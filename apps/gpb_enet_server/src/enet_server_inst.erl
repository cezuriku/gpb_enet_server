-module(enet_server_inst).

-behaviour(gen_server).
-behaviour(rt_room_observer).

-include("proto/EnetMessage_pb.hrl").

%% API
-export([
    start_link/1,
    handle_new_frame/5,
    stop/1
]).

%% gen_server callback
-export([
    terminate/2,
    code_change/4,
    init/1,
    handle_cast/2,
    handle_call/3,
    handle_info/2
]).

%%====================================================================
%% API
%%====================================================================

start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

-spec handle_new_frame(
    Pid :: pid(),
    Frame :: integer(),
    AddedPlayers :: rt_room:players(),
    UpdatedPlayers :: rt_room:players(),
    RemovedPlayers :: [rt_room:player_id()]
) -> ok.
handle_new_frame(
    Pid,
    Frame,
    AddedPlayers,
    UpdatedPlayers,
    RemovedPlayers
) ->
    gen_server:cast(
        Pid,
        {new_frame, Frame, AddedPlayers, UpdatedPlayers, RemovedPlayers}
    ).

stop(Pid) ->
    gen_server:stop(Pid).

%%====================================================================
%% gen_server callbacks
%%====================================================================

terminate(_Reason, _Data) ->
    ok.

code_change(_Vsn, State, Data, _Extra) ->
    {ok, State, Data}.

init([PeerInfo]) ->
    io:format("Client connected~n", []),
    {ok, #{
        peer => PeerInfo,
        buffer_to_client => queue:new(),
        client_frame => 0,
        client_ack => 0
    }}.

handle_cast(
    {new_frame, Frame, AddedPlayers, UpdatedPlayers, _RemovedPlayers},
    #{init := true} = Data
) ->
    NewData =
        send_frame(Frame, maps:merge(AddedPlayers, UpdatedPlayers), #{}, [], Data),
    {noreply, maps:without([init], NewData)};
handle_cast(
    {new_frame, Frame, AddedPlayers, UpdatedPlayers, RemovedPlayers},
    Data
) ->
    NewData =
        send_frame(Frame, AddedPlayers, UpdatedPlayers, RemovedPlayers, Data),
    {noreply, NewData};
handle_cast(EventContent, Data) ->
    print_unhandled_event(cast, EventContent, Data),
    {noreply, Data}.

handle_call(EventContent, _From, Data) ->
    print_unhandled_event(call, EventContent, Data),
    {reply,
        {error,
            {unhandled_event, #{
                event => EventContent,
                data => Data
            }}},
        Data}.

handle_info(
    {enet, disconnected, remote, _RemotePeer, _ConnectID},
    Data
) ->
    handle_disconnect(Data),
    {stop, normal, Data};
handle_info(
    {enet, 1, {reliable, Bin}},
    Data0
) ->
    Msg = 'EnetMessage_pb':decode_msg(Bin, 'ReliableClientMessage'),
    Data1 = handle_reliable_message(Msg, Data0),
    {noreply, Data1};
handle_info(
    {enet, 2, {unsequenced, _Count, Bin}},
    Data
) ->
    Msg = 'EnetMessage_pb':decode_msg(Bin, 'UnreliableClientMessage'),
    %%io:format("Message received: ~p~n", [Msg]),
    Data1 = handle_unreliable_message(Msg, Data),
    {noreply, Data1};
handle_info(
    timeout_on_ping,
    Data
) ->
    handle_disconnect(Data),
    {stop, normal, Data};
handle_info(EventContent, Data) ->
    print_unhandled_event(info, EventContent, Data),
    {noreply, Data}.

%%====================================================================
%% Internal functions
%%====================================================================

print_unhandled_event(Type, Content, Data) ->
    io:format(
        "Unhandled event:~n~p~n",
        [
            #{
                event_type => Type,
                event_content => Content,
                data => Data
            }
        ]
    ).

handle_unreliable_message(
    #'UnreliableClientMessage'{frame = NewFrame, ack = Ack, infos = ClientInfos},
    #{
        client_frame := Frame,
        room := Room,
        player_id := Id
    } = Data
) when NewFrame > Frame ->
    handle_client_infos(ClientInfos, NewFrame, Frame, Room, Id),
    Data#{
        client_frame => NewFrame,
        client_ack => Ack
    };
handle_unreliable_message(
    #'UnreliableClientMessage'{},
    Data
) ->
    Data.

handle_reliable_message(
    #'ReliableClientMessage'{content = {joinGame, #'JoinGame'{}}},
    #{
        peer := #{channels := Channels}
    } = Data
) ->
    {ok, Room} = rt_room:get_or_create(main_room),
    {Id, _Players} = rt_room:add_player(Room, ?MODULE, self()),
    io:format("Join Game id:~p~n", [Id]),
    Message = #'ReliableServerMessage'{
        content = {joinGameAccepted, #'JoinGameAccepted'{id = Id}}
    },
    MessageBin = 'EnetMessage_pb':encode_msg(Message, 'ReliableServerMessage'),
    {ok, Channel} = maps:find(1, Channels),
    enet:send_reliable(Channel, MessageBin),
    Data#{
        room => Room,
        player_id => Id,
        init => true
    }.

handle_client_infos([], _NewFrame, _Frame, _Room, _Id) ->
    ok;
handle_client_infos(_ClientInfos, Frame, Frame, _Room, _Id) ->
    ok;
handle_client_infos(
    [#'ClientInfo'{x = X, y = Y} | ClientInfos],
    NewFrame,
    Frame,
    Room,
    Id
) ->
    rt_room:move_player(Room, Id, NewFrame, {X, Y}),
    handle_client_infos(ClientInfos, NewFrame - 1, Frame, Room, Id).

send_frame(
    Frame,
    AddedPlayers,
    UpdatedPlayers,
    RemovedPlayers,
    #{
        peer := #{channels := Channels},
        buffer_to_client := Buffer0,
        client_frame := CFrame,
        client_ack := CAck
    } = Data
) ->
    io:format("~p ~p ~p~n", [
        maps:keys(AddedPlayers),
        maps:keys(UpdatedPlayers),
        RemovedPlayers
    ]),
    ServerInfo = #'ServerInfo'{
        players = [
            #'PlayerStatus'{id = Id, x = X, y = Y}
            || {Id, {X, Y}} <- maps:to_list(UpdatedPlayers)
        ],
        addedPlayers = [
            #'NewPlayer'{
                status = #'PlayerStatus'{id = Id, x = X, y = Y}
            }
            || {Id, {X, Y}} <- maps:to_list(AddedPlayers)
        ],
        removedPlayers = RemovedPlayers
    },
    Buffer1 = queue:in_r(ServerInfo, Buffer0),
    Buffer2 =
        case CAck of
            0 ->
                Buffer1;
            _ ->
                {Buff, _} = queue:split(Frame - CAck, Buffer1),
                Buff
        end,
    Message = #'UnreliableServerMessage'{
        frame = Frame,
        ack = CFrame,
        infos = queue:to_list(Buffer2)
    },
    MessageBin = 'EnetMessage_pb':encode_msg(Message, 'UnreliableServerMessage'),
    {ok, Channel} = maps:find(2, Channels),
    enet:send_unsequenced(Channel, MessageBin),
    Data#{
        buffer_to_client := Buffer2
    }.

handle_disconnect(#{
    room := Room
}) ->
    rt_room:remove_player(Room, self()),
    io:format("Client disconnected~n", []);
handle_disconnect(_Data) ->
    io:format("Client disconnected~n", []).

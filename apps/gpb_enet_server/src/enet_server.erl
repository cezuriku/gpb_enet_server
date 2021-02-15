-module(enet_server).

-behaviour(gen_server).

%% API
-export([
    start_link/2,
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

start_link(Port, MFA) ->
    gen_server:start_link(?MODULE, [Port, MFA], []).

stop(Pid) ->
    gen_server:stop(Pid).

%%====================================================================
%% gen_server callbacks
%%====================================================================

terminate(_Reason, Port) ->
    ok = enet:stop_host(Port),
    ok.

code_change(_Vsn, State, Data, _Extra) ->
    {ok, State, Data}.

init([Port, {Module, Function, Arg}]) ->
    ConnectFun = fun(PeerInfo) ->
        Module:Function([PeerInfo | Arg])
    end,
    {ok, _Host} = enet:start_host(
        Port,
        ConnectFun,
        [{peer_limit, 8}, {channel_limit, 3}]
    ),
    {ok, Port}.

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

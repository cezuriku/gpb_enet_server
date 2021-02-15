%%%-------------------------------------------------------------------
%% @doc gpb_enet_server top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(gpb_enet_server_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_all,
        intensity => 0,
        period => 1
    },

    EnetServer = #{
        id => enet_server,
        start => {enet_server, start_link, [10000, {enet_server_inst, start_link, []}]}
    },

    ChildSpecs = [EnetServer],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

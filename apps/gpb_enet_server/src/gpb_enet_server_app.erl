%%%-------------------------------------------------------------------
%% @doc gpb_enet_server public API
%% @end
%%%-------------------------------------------------------------------

-module(gpb_enet_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    gpb_enet_server_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

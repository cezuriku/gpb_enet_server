%% -*- coding: utf-8 -*-
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.16.0

-ifndef('EnetMessage_pb').
-define('EnetMessage_pb', true).

-define('EnetMessage_pb_gpb_version', "4.16.0").

-ifndef('RELIABLECLIENTMESSAGE_PB_H').
-define('RELIABLECLIENTMESSAGE_PB_H', true).
-record('ReliableClientMessage',
        {content                :: {joinGame, 'EnetMessage_pb':'JoinGame'()} | undefined % oneof
        }).
-endif.

-ifndef('JOINGAME_PB_H').
-define('JOINGAME_PB_H', true).
-record('JoinGame',
        {name = []              :: iodata() | undefined, % = 1, optional
         info = undefined       :: 'EnetMessage_pb':'ClientInfo'() | undefined % = 2, optional
        }).
-endif.

-ifndef('RELIABLESERVERMESSAGE_PB_H').
-define('RELIABLESERVERMESSAGE_PB_H', true).
-record('ReliableServerMessage',
        {content                :: {joinGameAccepted, 'EnetMessage_pb':'JoinGameAccepted'()} | undefined % oneof
        }).
-endif.

-ifndef('JOINGAMEACCEPTED_PB_H').
-define('JOINGAMEACCEPTED_PB_H', true).
-record('JoinGameAccepted',
        {id = 0                 :: integer() | undefined, % = 1, optional, 32 bits
         frame = 0              :: integer() | undefined, % = 2, optional, 32 bits
         players = []           :: ['EnetMessage_pb':'PlayerStatus'()] | undefined % = 3, repeated
        }).
-endif.

-ifndef('UNRELIABLECLIENTMESSAGE_PB_H').
-define('UNRELIABLECLIENTMESSAGE_PB_H', true).
-record('UnreliableClientMessage',
        {frame = 0              :: non_neg_integer() | undefined, % = 1, optional, 32 bits
         ack = 0                :: non_neg_integer() | undefined, % = 2, optional, 32 bits
         infos = []             :: ['EnetMessage_pb':'ClientInfo'()] | undefined % = 3, repeated
        }).
-endif.

-ifndef('CLIENTINFO_PB_H').
-define('CLIENTINFO_PB_H', true).
-record('ClientInfo',
        {x = 0                  :: integer() | undefined, % = 1, optional, 32 bits
         y = 0                  :: integer() | undefined % = 2, optional, 32 bits
        }).
-endif.

-ifndef('UNRELIABLESERVERMESSAGE_PB_H').
-define('UNRELIABLESERVERMESSAGE_PB_H', true).
-record('UnreliableServerMessage',
        {frame = 0              :: non_neg_integer() | undefined, % = 1, optional, 32 bits
         ack = 0                :: non_neg_integer() | undefined, % = 2, optional, 32 bits
         infos = []             :: ['EnetMessage_pb':'ServerInfo'()] | undefined % = 3, repeated
        }).
-endif.

-ifndef('SERVERINFO_PB_H').
-define('SERVERINFO_PB_H', true).
-record('ServerInfo',
        {players = []           :: ['EnetMessage_pb':'PlayerStatus'()] | undefined, % = 1, repeated
         removedPlayers = []    :: [integer()] | undefined, % = 2, repeated, 32 bits
         addedPlayers = []      :: ['EnetMessage_pb':'NewPlayer'()] | undefined % = 3, repeated
        }).
-endif.

-ifndef('PLAYERSTATUS_PB_H').
-define('PLAYERSTATUS_PB_H', true).
-record('PlayerStatus',
        {id = 0                 :: integer() | undefined, % = 1, optional, 32 bits
         x = 0                  :: integer() | undefined, % = 2, optional, 32 bits
         y = 0                  :: integer() | undefined % = 3, optional, 32 bits
        }).
-endif.

-ifndef('NEWPLAYER_PB_H').
-define('NEWPLAYER_PB_H', true).
-record('NewPlayer',
        {name = []              :: iodata() | undefined, % = 1, optional
         status = undefined     :: 'EnetMessage_pb':'PlayerStatus'() | undefined % = 2, optional
        }).
-endif.

-endif.

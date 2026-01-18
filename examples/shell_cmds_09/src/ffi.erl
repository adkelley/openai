-module(ffi).
-export([ls/0, pwd/0]).

ls() ->
    Port = open_port(
        {spawn, "ls"},
        [binary, exit_status, use_stdio]
    ),
    collect(Port, []).

pwd() ->
    Port = open_port(
        {spawn, "pwd"},
        [binary, exit_status, use_stdio]
    ),
    collect(Port, []).

collect(Port, Acc) ->
    receive
        {Port, {data, Bin}} ->
            collect(Port, [Bin | Acc]);

        {Port, {exit_status, Status}} ->
            {ok, Status, iolist_to_binary(lists:reverse(Acc))}
    end.

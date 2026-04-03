-module(ffi).
-export([ls/0, pwd/0, cmd/1]).

ls() ->
    Port = open_port(
        {spawn_executable, "/bin/ls"},
        [binary, exit_status, use_stdio]
    ),
    collect(Port, []).

pwd() ->
    Port = open_port(
        {spawn_executable, "/bin/pwd"},
        [binary, exit_status, use_stdio]
    ),
    collect(Port, []).

cmd(Cmd) ->
    CmdString = unicode:characters_to_list(Cmd),
    Port = open_port(
        {spawn_executable, "/bin/sh"},
        [
            binary,
            exit_status,
            use_stdio,
            stderr_to_stdout,
            {args, ["-c", CmdString]}
        ]
    ),
    collect(Port, []).

collect(Port, Acc) ->
    receive
        {Port, {data, Bin}} ->
            collect(Port, [Bin | Acc]);

        {Port, {exit_status, Status}} ->
            {ok, Status, iolist_to_binary(lists:reverse(Acc))}
    end.

-module(ffi).

-export([ls/0, pwd/0, run_command/2]).

ls() ->
    Port = open_port({spawn_executable, "/bin/ls"}, [binary, exit_status, use_stdio]),
    collect(Port, []).

pwd() ->
    Port = open_port({spawn_executable, "/bin/pwd"}, [binary, exit_status, use_stdio]),
    collect(Port, []).

run_command(Program, Args) ->
    Port =
        open_port(
            {spawn_executable, unicode:characters_to_list(Program)},
            [
                {args, lists:map(fun unicode:characters_to_list/1, Args)},
                binary,
                exit_status,
                use_stdio
            ]
        ),
    collect(Port, []).

collect(Port, Acc) ->
    receive
        {Port, {data, Bin}} ->
            collect(Port, [Bin | Acc]);
        {Port, {exit_status, Status}} ->
            {ok, Status, unicode:characters_to_list(iolist_to_binary(lists:reverse(Acc)))}
    end.

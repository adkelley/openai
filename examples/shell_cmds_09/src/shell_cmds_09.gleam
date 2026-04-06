import gleam/erlang/atom.{type Atom}
import gleam/erlang/charlist.{type Charlist}
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/content
import openai/types/responses/message
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/shell
import openai/types/role

type SafeCommand {
  SafeCommand(program: String, args: List(String))
}

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let input_text =
    "What is the current directory? Also, please list out the files in that directory"

  let hop1 =
    [
      message.new()
      |> message.with_role(role.User)
      |> message.with_content([
        content.new_text(input_text) |> content.TextContentItem,
      ])
      |> response.MessageItem,
    ]
    |> response.Items
  io.println("\nPrompt: " <> input_text)

  let local_environment =
    shell.LocalEnvironmentItem(shell.LocalEnvironment(skills: None))
  let shell_tool =
    shell.new()
    |> shell.environment(local_environment)
    |> tool.ShellTool

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_input(hop1)
    |> responses.with_instructions(
      "The local bash environment is on macOS."
      <> "\n Please separate the user's prompt into individual shell commands\n",
    )
    |> responses.with_tools([shell_tool])

  let assert Ok(#(id, input_output)) =
    responses.create_with_decoder(client, request, response.decode_id_output())
  let hop2 =
    input_output
    |> map_shell_call_outputs()
    |> response.Items

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_previous_response_id(id)
    |> responses.with_input(hop2)

  let assert Ok(messages) =
    responses.create_with_decoder(
      client,
      request,
      message.decode_output_message_texts(),
    )

  let text =
    list.fold(list.flatten(messages), "", fn(acc, text) { acc <> text })

  io.println("Answer: " <> text)

  Ok(Nil)
}

fn map_shell_call_outputs(
  items: List(response.InputOutput),
) -> List(response.InputOutput) {
  list.fold(items, [], fn(acc, item) {
    case item {
      response.ShellCallItem(shell.ShellCall(call_id:, action:, ..)) -> {
        let output = process_shell_commands(action.commands)

        list.prepend(
          acc,
          shell.new_shell_call_output(call_id, output)
            |> response.ShellCallOutputItem,
        )
      }
      _ -> acc
    }
  })
}

fn process_shell_commands(commands: List(String)) -> List(shell.Output) {
  list.map(commands, run_safe_command)
}

fn run_safe_command(command: String) -> shell.Output {
  case parse_safe_command(command) {
    Ok(SafeCommand(program:, args:)) -> {
      let #(_ok, status, xs) = run_command(program, args)
      let text = charlist.to_string(xs) |> string.trim
      shell.Output(
        stdout: text,
        stderr: "",
        outcome: shell.Outcome(type_: Some("exit"), exit_code: Some(status)),
        created_by: None,
      )
    }
    Error(message) ->
      shell.Output(
        stdout: "",
        stderr: message,
        outcome: shell.Outcome(type_: Some("exit"), exit_code: Some(126)),
        created_by: None,
      )
  }
}

fn parse_safe_command(command: String) -> Result(SafeCommand, String) {
  let command = string.trim(command)
  let forbidden_tokens = ["&&", ";", "||", "|", ">", "<", "$(", "`"]

  case
    list.any(forbidden_tokens, fn(token) { string.contains(command, token) })
  {
    True ->
      Error(
        "Rejected unsafe shell command: "
        <> command
        <> ". Shell chaining, redirection, and substitution operators are not allowed.",
      )
    False -> {
      let parts =
        command
        |> string.split(" ")
        |> list.filter(fn(part) { part != "" })

      case parts {
        ["pwd"] -> Ok(SafeCommand(program: "/bin/pwd", args: []))
        ["ls"] -> Ok(SafeCommand(program: "/bin/ls", args: []))
        ["ls", "-l"] -> Ok(SafeCommand(program: "/bin/ls", args: ["-l"]))
        ["ls", "-a"] -> Ok(SafeCommand(program: "/bin/ls", args: ["-a"]))
        ["ls", "-la"] -> Ok(SafeCommand(program: "/bin/ls", args: ["-la"]))
        ["ls", "-al"] -> Ok(SafeCommand(program: "/bin/ls", args: ["-al"]))
        ["echo", ..rest] -> Ok(SafeCommand(program: "/bin/echo", args: rest))
        ["printf", ..rest] ->
          Ok(SafeCommand(program: "/usr/bin/printf", args: rest))
        _ ->
          Error(
            "Rejected unsupported shell command: "
            <> command
            <> ". Only pwd, echo, printf, and ls variants are allowed.",
          )
      }
    }
  }
}

// fn extract_output_message_text(messages: List(String)) -> String {
//   list.fold(messages, "", fn(acc, output_text) {
//     acc <> text
//   })
// }

// fn decode_output_item_text() -> decode.Decoder(Option(String)) {
//   use type_ <- decode.field("type", decode.string)
//   case type_ {
//     "message" ->
//       decode.at(["content"], decode.at([0], decode.at(["text"], decode.string)))
//       |> decode.map(Some)
//     _ -> decode.success(None)
//   }
// }

// fn first_non_empty_text(items: List(String)) -> Option(String) {
//   case items {
//     [text, ..rest] ->
//       case string.trim(text) {
//         "" -> first_non_empty_text(rest)
//         _ -> Some(text)
//       }
//     [] -> None
//   }
// }

@external(erlang, "ffi", "run_command")
fn run_command(program: String, args: List(String)) -> #(Atom, Int, Charlist)

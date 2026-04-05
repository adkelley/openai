/// Registers a local `skills.md` weather skill through the shell tool and asks
/// the model to explain it without invoking any tools.
import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/string
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/content
import openai/types/responses/message
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/search_context_size
import openai/types/responses/tools/shell
import openai/types/responses/tools/user_location
import openai/types/responses/tools/web_search
import openai/types/role

type Hop1Response {
  Hop1Response(id: String, shell_calls: List(ShellCall))
}

type ShellCall {
  ShellCall(call_id: String, commands: List(String), max_output_length: Int)
}

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let input_text = "What is the weather in Phoenix, Arizona today?"
  let hop1 = [
    message.new()
    |> message.with_role(role.User)
    |> message.with_content([
      content.new_text(input_text) |> content.TextContentItem,
    ])
    |> response.MessageItem,
  ]
  io.println("\nPrompt: " <> input_text)

  let weather_skill =
    shell.LocalSkill(
      description: "Retrieve current weather for a given city",
      name: "get_weather",
      path: "./weather",
    )

  let local_environment =
    shell.LocalEnvironmentItem(
      shell.LocalEnvironment(skills: Some([weather_skill])),
    )
  let shell_tool =
    shell.new()
    |> shell.environment(local_environment)
    |> tool.ShellTool

  let user_location =
    user_location.new()
    |> user_location.with_city("Phoenix")
    |> user_location.with_country("US")

  let web_search_tool =
    web_search.new_web_search()
    |> web_search.user_location(user_location)
    |> web_search.filters(["weather.gov"])
    |> web_search.search_context_size(search_context_size.Low)
    |> tool.WebSearchTool

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_input(response.Items(hop1))
    |> responses.with_instructions(
      "The local shell environment is macOS. Answer with only the current forecast. Do not offer additional help or suggest follow-up actions.",
    )
    |> responses.with_tools([shell_tool, web_search_tool])

  let assert Ok(hop1_response) =
    responses.create_with_decoder(client, request, decode_hop1_response())

  let hop2 =
    hop1_response.shell_calls
    |> map_shell_call_outputs()
    |> response.Items

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_previous_response_id(hop1_response.id)
    |> responses.with_input(hop2)

  let assert Ok(text) =
    responses.create_with_decoder(client, request, decode_output_message_text())

  io.println("\nCurrent forecast: " <> text)

  Ok(Nil)
}

fn decode_hop1_response() -> decode.Decoder(Hop1Response) {
  use id <- decode.field("id", decode.string)
  use output <- decode.field("output", decode.list(decode_shell_call_item()))
  decode.success(Hop1Response(id:, shell_calls: option.values(output)))
}

fn decode_shell_call_item() -> decode.Decoder(Option(ShellCall)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "shell_call" -> {
      use call_id <- decode.field("call_id", decode.string)
      use commands <- decode.subfield(
        ["action", "commands"],
        decode.list(decode.string),
      )
      use max_output_length <- decode.subfield(
        ["action", "max_output_length"],
        decode.int,
      )
      decode.success(Some(ShellCall(call_id:, commands:, max_output_length:)))
    }
    _ -> decode.success(None)
  }
}

fn map_shell_call_outputs(calls: List(ShellCall)) -> List(response.InputOutput) {
  case calls {
    [ShellCall(call_id:, commands:, max_output_length:), ..rest] -> {
      let assert [command, ..] = commands
      let output =
        shell.Output(
          stdout: cmd(command)
            |> command_output_to_string(),
          stderr: "",
          outcome: shell.Outcome(type_: Some("exit"), exit_code: Some(0)),
          created_by: None,
        )
      [
        response.ShellCallOutputItem(shell.ShellCallOutput(
          call_id:,
          max_output_length: Some(max_output_length),
          output: [output],
          id: None,
          status: None,
        )),
        ..map_shell_call_outputs(rest)
      ]
    }
    [] -> []
  }
}

fn decode_output_message_text() -> decode.Decoder(String) {
  use outputs <- decode.field("output", decode.list(decode_output_item_text()))
  case first_non_empty_text(option.values(outputs)) {
    Some(text) -> decode.success(text)
    None -> decode.failure("", expected: "non-empty message output text")
  }
}

fn decode_output_item_text() -> decode.Decoder(Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "message" ->
      decode.at(["content"], decode.at([0], decode.at(["text"], decode.string)))
      |> decode.map(Some)
    _ -> decode.success(None)
  }
}

fn first_non_empty_text(items: List(String)) -> Option(String) {
  case items {
    [text, ..rest] ->
      case string.trim(text) {
        "" -> first_non_empty_text(rest)
        _ -> Some(text)
      }
    [] -> None
  }
}

fn command_output_to_string(output: #(Atom, Int, BitArray)) -> String {
  let #(_ok, _status, bytes) = output
  let assert Ok(text) = bit_array.to_string(bytes)
  string.trim(text)
}

@external(erlang, "ffi", "cmd")
fn cmd(c: String) -> #(Atom, Int, BitArray)

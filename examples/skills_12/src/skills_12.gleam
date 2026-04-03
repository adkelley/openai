/// Registers a local `skills.md` weather skill through the shell tool and asks
/// the model to explain it without invoking any tools.
import gleam/bit_array
import gleam/erlang/atom.{type Atom}
import gleam/io
import gleam/list
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

pub fn main() -> Result(response.Response, OpenAIError) {
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

  let assert Ok(response) = responses.create(client, request)
  let input_list = list.append(hop1, response.output)

  let shell_call_output =
    list.fold(response.output, [], fn(acc, item: response.InputOutput) {
      case item {
        response.ShellCallItem(shell.ShellCall(action:, call_id:, ..)) -> {
          let assert [command, ..] = action.commands
          let shell_call_output = {
            let assert Some(max_output_length) = action.max_output_length
            let output =
              shell.Output(
                stdout: cmd(command)
                  |> command_output_to_string(),
                stderr: "",
                outcome: shell.Outcome(type_: Some("exit"), exit_code: Some(0)),
                created_by: None,
              )
            response.ShellCallOutputItem(shell.ShellCallOutput(
              call_id:,
              max_output_length: Some(max_output_length),
              output: [
                output,
              ],
              id: None,
              status: None,
            ))
          }
          list.append(acc, [shell_call_output])
        }
        _ -> acc
      }
    })

  let hop2 = list.append(input_list, shell_call_output)

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_input(response.Items(hop2))

  let assert Ok(response) = responses.create(client, request)
  let assert Some(message.ResponseOutputMessage(content:, ..)) =
    find_last_output_message(response.output)
  let assert Ok(message.OutputTextItem(message.OutputText(text:, ..))) =
    list.first(content)

  io.println("\nCurrent forecast: " <> text)

  Ok(response)
}

fn find_last_output_message(
  output: List(response.InputOutput),
) -> Option(message.ResponseOutputMessage) {
  case output {
    [response.ResponseOutputMessageItem(response_output_message)] ->
      Some(response_output_message)
    [response.ResponseOutputMessageItem(_), ..rest] ->
      find_last_output_message(rest)
    [_, ..rest] -> find_last_output_message(rest)
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

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

pub fn main() -> Result(response.Response, OpenAIError) {
  let assert Ok(client) = client.new()

  let input_text = "get the current directory"
  // let input_text = "Execute: ls -al"

  let hop1 = [
    message.new()
    |> message.with_role(role.User)
    |> message.with_content([
      content.new_text(input_text) |> content.TextContentItem,
    ])
    |> response.MessageItem,
  ]
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
    |> responses.with_input(response.Items(hop1))
    |> responses.with_instructions("The local bash environment is on macOS")
    // Define the list of callable tools for the model
    |> responses.with_tools([shell_tool])

  let assert Ok(response) = responses.create(client, request)
  let input_list = list.append(hop1, response.output)
  let shell_call_output =
    list.fold(response.output, [], fn(acc, item: response.InputOutput) {
      case item {
        response.ShellCallItem(shell.ShellCall(action:, call_id:, ..)) -> {
          let assert [command, ..] = action.commands
          let shell_call_output = case command {
            "pwd" -> {
              let pwd_ = fn() {
                let #(_ok, _status, xs) = pwd()
                charlist.to_string(xs) |> string.trim
              }

              let assert Some(max_output_length) = action.max_output_length
              let output =
                shell.Output(
                  stdout: pwd_(),
                  stderr: "",
                  outcome: shell.Outcome(
                    type_: Some("exit"),
                    exit_code: Some(0),
                  ),
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
            _ -> panic as "invaild shell command: "
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
  let assert [
    response.ResponseOutputMessageItem(message.ResponseOutputMessage(
      content:,
      ..,
    )),
    ..
  ] = response.output
  let assert [message.OutputTextItem(message.OutputText(text:, ..))] = content

  io.println("Answer: " <> text)

  Ok(response)
}

@external(erlang, "ffi", "pwd")
fn pwd() -> #(Atom, Int, Charlist)

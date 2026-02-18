import envoy
import gleam/erlang/atom.{type Atom}
import gleam/erlang/charlist.{type Charlist}
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import openai/error.{type OpenaiError}
import openai/responses
import openai/types/responses/create_response as cr
import openai/types/responses/response.{type Response} as res
import openai/types/shared

pub fn main() -> Result(Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  // let input_text = "list the contents of the current directory"
  let input_text = "print the current working directory"
  // let input_text = "find me the largest markdown file in current directory"
  let hop1 = [
    cr.InputListItemMessage(cr.RoleContent(
      role: "user",
      content: cr.ContentInputText(input_text),
    )),
  ]
  io.println("\nPrompt: " <> input_text)

  let config =
    responses.default_request()
    |> responses.model(shared.GPT51)
    |> responses.input(cr.InputList(hop1))
    |> responses.instructions(Some("The local bash environment is on Mac"))
    // Define the list of callable tools for the model
    |> responses.tools(Some([]), cr.ShellCall)

  let assert Ok(response) = responses.create(api_key, config)
  echo response.output

  // Step 1: parse the commands
  // Step 2: execute and store result of commands
  // Step 3: append the results (i.e., 'shell execution output') to hop2

  let hop2 =
    list.fold(response.output, hop1, fn(acc, item) {
      case item {
        res.OutputShellCall(id:, call_id:, action:, status:, environment:) -> {
          let req_action = case action {
            res.OutputShellCallAction(
              commands:,
              timeout_ms:,
              max_output_length:,
            ) -> {
              cr.OutputShellCallAction(
                commands:,
                timeout_ms:,
                max_output_length:,
              )
            }
          }
          list.append(acc, [
            cr.InputListItemMessage(cr.OutputShellCall(
              id:,
              call_id:,
              action: req_action,
              status:,
              environment:,
            )),
          ])
          |> fn(acc_) {
            let shell_call_output = case action {
              res.OutputShellCallAction(
                commands: _,
                timeout_ms: _,
                max_output_length:,
              ) -> {
                let pwd_ = fn() {
                  let #(_ok, _status, xs) = pwd()
                  charlist.to_string(xs) |> string.trim_end()
                }
                let output_list = [
                  cr.ShellExectionOutput(
                    stdout: pwd_(),
                    stderr: "",
                    outcome: cr.ShellExecutionOutcome(
                      type_: "exit",
                      exit_code: 0,
                    ),
                  ),
                ]
                cr.ShellCallOutput(
                  call_id:,
                  max_output_length:,
                  output: output_list,
                )
              }
            }
            list.append(acc_, [cr.InputListItemMessage(shell_call_output)])
          }
        }

        _ -> acc
      }
    })

  let config =
    responses.default_request()
    |> responses.model(shared.GPT51)
    |> responses.input(cr.InputList(hop2))

  let assert Ok(response) = responses.create(api_key, config)
  echo response.output

  Ok(response)
}

@external(erlang, "ffi", "pwd")
fn pwd() -> #(Atom, Int, Charlist)

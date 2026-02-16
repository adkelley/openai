import envoy
import gleam/erlang/atom.{type Atom}
import gleam/erlang/charlist.{type Charlist}
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import openai/error.{type OpenaiError}
import openai/responses
import openai/responses/types/request as req
import openai/responses/types/response as res
import openai/types as shared

pub fn main() -> Result(res.Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  // let input_text = "list the contents of the current directory"
  let input_text = "print the current working directory"
  // let input_text = "find me the largest markdown file in current directory"
  let hop1 = [
    req.InputListItemMessage(req.RoleContent(
      role: "user",
      content: req.ContentInputText(input_text),
    )),
  ]
  io.println("\nPrompt: " <> input_text)

  let config =
    responses.default_request()
    |> responses.model(shared.GPT51)
    |> responses.input(req.InputList(hop1))
    |> responses.instructions(Some("The local bash environment is on Mac"))
    // Define the list of callable tools for the model
    |> responses.tools(Some([]), req.ShellCall)

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
              req.OutputShellCallAction(
                commands:,
                timeout_ms:,
                max_output_length:,
              )
            }
          }
          list.append(acc, [
            req.InputListItemMessage(req.OutputShellCall(
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
                  req.ShellExectionOutput(
                    stdout: pwd_(),
                    stderr: "",
                    outcome: req.ShellExecutionOutcome(
                      type_: "exit",
                      exit_code: 0,
                    ),
                  ),
                ]
                req.ShellCallOutput(
                  call_id:,
                  max_output_length:,
                  output: output_list,
                )
              }
            }
            list.append(acc_, [req.InputListItemMessage(shell_call_output)])
          }
        }

        _ -> acc
      }
    })

  let config =
    responses.default_request()
    |> responses.model(shared.GPT51)
    |> responses.input(req.InputList(hop2))

  let assert Ok(response) = responses.create(api_key, config)
  echo response.output

  Ok(response)
}

@external(erlang, "ffi", "pwd")
fn pwd() -> #(Atom, Int, Charlist)

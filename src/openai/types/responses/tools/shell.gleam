import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/types/helpers
import openai/types/responses/network_policy

pub type LocalAction {
  LocalAction(
    /// The commands to execute.
    commands: List(String),
    /// Environment variables to set for the command execution.
    env: List(#(String, String)),
    // type: "exec"
    /// Maximum execution time for the command, in milliseconds.
    timeout_ms: Option(Float),
    /// The user to run the commands as.
    user: Option(String),
    /// The working directory to run the commands in.
    working_directory: Option(String),
  )
}

pub type Status {
  InProgress
  Completed
  Incomplete
}

fn encode_status(status: Status) -> Json {
  case status {
    InProgress -> "in_progress"
    Completed -> "completed"
    Incomplete -> "incomplete"
  }
  |> json.string
}

fn decode_status() -> Decoder(Status) {
  decode.string
  |> decode.map(fn(status) {
    case status {
      "in_progress" -> InProgress
      "completed" -> Completed
      "incomplete" -> Incomplete
      _ -> panic as status
    }
  })
}

pub type LocalShell {
  // type: "local_shell"
  LocalShell
}

pub fn encode_local_shell() -> Json {
  json.object([#("type", json.string("local_shell"))])
}

pub fn decode_local_shell() -> Decoder(LocalShell) {
  use type_ <- decode.field("type", decode.string)
  assert type_ == "local_shell"
  decode.success(LocalShell)
}

pub type LocalShellCall {
  LocalShellCall(
    /// The unique ID of the local shell call.
    id: String,
    /// The action requested for the local shell.
    action: LocalAction,
    /// The ID of the local shell tool call.
    call_id: String,
    /// The status of the item. One of in_progress, completed, or incomplete.
    status: Status,
    // type: "local_shell_call"
  )
}

pub type LocalShellCallOutput {
  LocalShellCallOutput(
    /// The unique ID of the local shell call output.
    id: String,
    /// The text output emitted by the local shell call.
    output: String,
    /// The ID of the local shell tool call that produced this output.
    call_id: String,
    /// The status of the item. One of in_progress, completed, or incomplete.
    status: Status,
    // type: "local_shell_call_output"
  )
}

pub type ShellCall {
  ShellCall(
    /// The unique ID of the shell call.
    id: String,
    /// The shell action requested by the model.
    action: Action,
    /// The ID of the shell tool call.
    call_id: String,
    /// The status of the item. One of in_progress, completed, or incomplete.
    status: Status,
    // type: "shell_call"
  )
}

pub fn encode_shell_call(shell_call: ShellCall) -> Json {
  json.object([
    #("id", json.string(shell_call.id)),
    #("action", encode_action(shell_call.action)),
    #("call_id", json.string(shell_call.call_id)),
    #("status", encode_status(shell_call.status)),
    #("type", json.string("shell_call")),
  ])
}

pub fn decode_shell_call() -> Decoder(ShellCall) {
  use id <- decode.field("id", decode.string)
  use action <- decode.field("action", decode_action())
  use call_id <- decode.field("call_id", decode.string)
  use status <- decode.field("status", decode_status())
  decode.success(ShellCall(id:, action:, call_id:, status:))
}

pub type Action {
  Action(
    /// The commands to execute.
    commands: List(String),
    /// The maximum output length to return from command execution.
    max_output_length: Option(Int),
    /// The timeout for command execution, in milliseconds.
    timeout_ms: Option(Int),
  )
}

fn encode_action(action: Action) -> Json {
  list.prepend([], #("commands", json.array(action.commands, json.string)))
  |> helpers.encode_option(
    "max_output_length",
    action.max_output_length,
    json.int,
  )
  |> helpers.encode_option("timeout_ms", action.timeout_ms, json.int)
  |> json.object
}

fn decode_action() -> Decoder(Action) {
  use commands <- decode.field("commands", decode.list(decode.string))
  use max_output_length <- decode.field(
    "max_output_length",
    decode.optional(decode.int),
  )
  use timeout_ms <- decode.field("timeout_ms", decode.optional(decode.int))
  decode.success(Action(commands:, max_output_length:, timeout_ms:))
}

pub type Shell {
  Shell(
    // type: "shell"
    environment: Option(Environment),
  )
}

pub fn new() -> Shell {
  Shell(environment: None)
}

pub fn environment(_shell: Shell, environment: Environment) -> Shell {
  Shell(environment: Some(environment))
}

pub fn encode_shell(shell: Shell) -> Json {
  [#("type", json.string("shell"))]
  |> helpers.encode_option("environment", shell.environment, encode_environment)
  |> json.object
}

pub fn decode_shell() -> Decoder(Shell) {
  use type_ <- decode.field("type", decode.string)
  assert type_ == "shell"
  use environment <- decode.field(
    "environment",
    decode.optional(decode_environment()),
  )
  decode.success(Shell(environment:))
}

pub type Environment {
  ContainerAutoItem(ContainerAuto)
  LocalEnvironmentItem(LocalEnvironment)
  ContainerReferenceItem(ContainerReference)
}

fn encode_environment(environment: Environment) -> Json {
  case environment {
    ContainerAutoItem(auto_) -> encode_container_auto(auto_)
    LocalEnvironmentItem(local) -> encode_local_environment(local)
    ContainerReferenceItem(reference) -> encode_container_reference(reference)
  }
}

fn decode_environment() -> Decoder(Environment) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "container_auto" -> decode_container_auto() |> decode.map(ContainerAutoItem)
    "local" -> decode_local_environment() |> decode.map(LocalEnvironmentItem)
    "container_reference" ->
      decode_container_reference() |> decode.map(ContainerReferenceItem)
    _ -> panic as type_
  }
}

pub type LocalEnvironment {
  LocalEnvironment(
    // type: local
    /// An optional list of skills.
    skills: Option(List(LocalSkill)),
  )
}

fn encode_local_environment(env: LocalEnvironment) -> Json {
  [
    #("type", json.string("local")),
  ]
  |> helpers.encode_option_list("skills", env.skills, encode_local_skill)
  |> json.object
}

fn decode_local_environment() -> Decoder(LocalEnvironment) {
  use skills <- decode.optional_field(
    "skills",
    None,
    decode.optional(decode.list(decode_local_skill())),
  )
  decode.success(LocalEnvironment(skills:))
}

pub type LocalSkill {
  LocalSkill(
    /// The description of the skill.
    description: String,
    /// The name of the skill.
    name: String,
    /// The path to the directory containing the skill.
    path: String,
  )
}

fn encode_local_skill(skill: LocalSkill) -> Json {
  json.object([
    #("description", json.string(skill.description)),
    #("name", json.string(skill.name)),
    #("path", json.string(skill.path)),
  ])
}

fn decode_local_skill() -> Decoder(LocalSkill) {
  use description <- decode.field("description", decode.string)
  use name <- decode.field("name", decode.string)
  use path <- decode.field("path", decode.string)
  decode.success(LocalSkill(description:, name:, path:))
}

pub type ContainerAuto {
  ContainerAuto(
    // type: "container_auto"
    /// An optional list of uploaded files to make available to your code.
    file_ids: Option(List(String)),
    /// The memory limit for the container.
    memory_limit: Option(MemoryLimit),
    /// Network access policy for the container.
    network_policy: Option(network_policy.NetworkPolicy),
  )
}

fn encode_container_auto(auto_: ContainerAuto) -> Json {
  [
    #("type", json.string("container_auto")),
  ]
  |> helpers.encode_option_list("file_ids", auto_.file_ids, json.string)
  |> helpers.encode_option(
    "network_policy",
    auto_.network_policy,
    network_policy.encode_network_policy,
  )
  |> helpers.encode_option(
    "memory_limit",
    auto_.memory_limit,
    encode_memory_limit,
  )
  |> json.object
}

fn decode_container_auto() -> Decoder(ContainerAuto) {
  use file_ids <- decode.field(
    "file_ids",
    decode.optional(decode.list(decode.string)),
  )
  use memory_limit <- decode.optional_field(
    "memory_limit",
    None,
    decode.optional(decode_memory_limit()),
  )
  use network_policy <- decode.optional_field(
    "network_policy",
    None,
    decode.optional(network_policy.decode_network_policy()),
  )
  decode.success(ContainerAuto(file_ids:, memory_limit:, network_policy:))
}

pub type MemoryLimit {
  OneGB
  FourGB
  SixteenGB
  SixtyFourGB
}

fn encode_memory_limit(limit: MemoryLimit) -> Json {
  case limit {
    OneGB -> json.string("1g")
    FourGB -> json.string("4g")
    SixteenGB -> json.string("16g")
    SixtyFourGB -> json.string("64g")
  }
}

fn decode_memory_limit() -> Decoder(MemoryLimit) {
  decode.string
  |> decode.map(fn(limit) {
    case limit {
      "1g" -> OneGB
      "4g" -> FourGB
      "16g" -> SixteenGB
      "64g" -> SixtyFourGB
      _ -> panic as limit
    }
  })
}

pub type ContainerReference {
  ContainerReference(
    /// The ID of the referenced container.
    container_id: String,
    // type: "continer_reference"
  )
}

fn encode_container_reference(ref: ContainerReference) -> Json {
  json.object([
    #("type", json.string("container_reference")),
    #("container_id", json.string(ref.container_id)),
  ])
}

fn decode_container_reference() -> Decoder(ContainerReference) {
  use container_id <- decode.field("container_id", decode.string)
  decode.success(ContainerReference(container_id:))
}

pub type ShellCallOutput {
  ShellCallOutput(
    /// The unique ID of the shell call output.
    id: Option(String),
    /// The ID of the shell tool call that produced this output.
    call_id: String,
    /// Streamed output chunks emitted by the shell tool call.
    output: List(Output),
    /// The maximum output length configured for this shell call.
    max_output_length: Option(Int),
    /// The status of the shell call output.
    status: Option(Status),
    // type: "shell_call_output"
  )
}

pub fn encode_shell_call_output(output: ShellCallOutput) -> Json {
  [
    #("type", json.string("shell_call_output")),
    #("call_id", json.string(output.call_id)),
    #("output", json.array(output.output, encode_output)),
  ]
  |> helpers.encode_option("id", output.id, json.string)
  |> helpers.encode_option("status", output.status, encode_status)
  |> helpers.encode_option(
    "max_output_length",
    output.max_output_length,
    json.int,
  )
  |> json.object
}

pub fn decode_shell_call_output() -> Decoder(ShellCallOutput) {
  use id <- decode.field("id", decode.optional(decode.string))
  use call_id <- decode.field("call_id", decode.string)
  use status <- decode.field("status", decode.optional(decode_status()))
  use max_output_length <- decode.field(
    "max_output_length",
    decode.optional(decode.int),
  )
  use output <- decode.field("output", decode.list(decode_output()))
  decode.success(ShellCallOutput(
    id:,
    call_id:,
    output:,
    status:,
    max_output_length:,
  ))
}

pub fn new_shell_call_output(
  call_id: String,
  output: List(Output),
) -> ShellCallOutput {
  ShellCallOutput(
    id: None,
    call_id: call_id,
    output: output,
    status: None,
    max_output_length: None,
  )
}

pub fn shell_call_output_with_id(
  config: ShellCallOutput,
  id: String,
) -> ShellCallOutput {
  ShellCallOutput(..config, id: Some(id))
}

pub fn shell_call_output_with_status(
  config: ShellCallOutput,
  status: Status,
) -> ShellCallOutput {
  ShellCallOutput(..config, status: Some(status))
}

pub fn shell_call_output_with_max_output_length(
  config: ShellCallOutput,
  max_output_length: Int,
) -> ShellCallOutput {
  ShellCallOutput(..config, max_output_length: Some(max_output_length))
}

pub type Output {
  Output(
    /// Standard output emitted by the shell command.
    stdout: String,
    /// Standard error emitted by the shell command.
    stderr: String,
    /// The outcome of the shell command.
    outcome: Outcome,
    /// The actor that produced this output.
    created_by: Option(String),
  )
}

fn encode_output(output: Output) -> Json {
  [
    #("stdout", json.string(output.stdout)),
    #("stderr", json.string(output.stderr)),
    #("outcome", encode_outcome(output.outcome)),
  ]
  |> helpers.encode_option("created_by", output.created_by, json.string)
  |> json.object
}

fn decode_output() -> Decoder(Output) {
  use stderr <- decode.field("stderr", decode.string)
  use stdout <- decode.field("stdout", decode.string)
  use outcome <- decode.field("outcome", decode_outcome())
  use created_by <- decode.field("created_by", decode.optional(decode.string))
  decode.success(Output(stdout:, stderr:, outcome:, created_by:))
}

pub type Outcome {
  Outcome(type_: Option(String), exit_code: Option(Int))
}

fn encode_outcome(outcome: Outcome) -> Json {
  helpers.encode_option([], "type", outcome.type_, json.string)
  |> helpers.encode_option("exit_code", outcome.exit_code, json.int)
  |> json.object
}

fn decode_outcome() -> Decoder(Outcome) {
  use type_ <- decode.field("type", decode.optional(decode.string))
  use exit_code <- decode.field("exit_code", decode.optional(decode.int))
  decode.success(Outcome(type_:, exit_code:))
}

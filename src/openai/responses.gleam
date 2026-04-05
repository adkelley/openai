import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import openai/client.{type Client}
import openai/error.{type OpenAIError}
import openai/transport
import openai/types/responses/reasoning.{type ReasoningDef}
import openai/types/responses/response.{
  type CreateResponse, type InputOutputParam, type Response, type TextParam,
  CreateResponse,
}
import openai/types/responses/tool.{type Tool}
import openai/types/responses/tool_choice

const responses_url = "https://api.openai.com/v1/responses"

/// Default: Text Input
pub fn new() -> CreateResponse {
  CreateResponse(
    background: None,
    context_management: None,
    conversation_context: None,
    include: None,
    input: response.Text(""),
    instructions: None,
    max_output_tokens: None,
    max_tool_calls: None,
    metadata: None,
    model: "gpt-5-mini",
    parallel_tool_calls: None,
    prompt: None,
    prompt_cache_key: None,
    prompt_cache_retention: None,
    reasoning: None,
    safety_identifier: None,
    service_tier: None,
    store: None,
    stream_options: None,
    text: None,
    top_logprobs: None,
    top_p: None,
    truncation: None,
    temperature: None,
    stream: None,
    tool_choice: None,
    tools: None,
  )
}

pub fn with_model(request: CreateResponse, model: String) {
  CreateResponse(..request, model:)
}

pub fn with_input(
  request: CreateResponse,
  input: InputOutputParam,
) -> CreateResponse {
  CreateResponse(..request, input:)
}

pub fn with_instructions(
  request: CreateResponse,
  instructions: String,
) -> CreateResponse {
  CreateResponse(..request, instructions: Some(instructions))
}

pub fn with_previous_response_id(
  request: CreateResponse,
  previous_response_id: String,
) -> CreateResponse {
  CreateResponse(
    ..request,
    conversation_context: Some(response.ContinuePreviousResponse(
      previous_response_id,
    )),
  )
}

pub fn with_conversation(
  request: CreateResponse,
  conversation: response.ConversationParam(String),
) -> CreateResponse {
  CreateResponse(
    ..request,
    conversation_context: Some(response.ContinueConversation(conversation)),
  )
}

pub fn with_tool_choice(request: CreateResponse, tool_choice: tool_choice.Param) {
  CreateResponse(..request, tool_choice: Some(tool_choice))
}

pub fn with_tools(request: CreateResponse, tools: List(Tool)) {
  CreateResponse(..request, tools: Some(tools))
}

pub fn with_reasoning(request: CreateResponse, reasoning: ReasoningDef) {
  CreateResponse(..request, reasoning: Some(reasoning))
}

pub fn with_text(request: CreateResponse, text: TextParam) {
  CreateResponse(..request, text: Some(text))
}

pub fn create(
  client client: Client,
  request request: CreateResponse,
) -> Result(Response, OpenAIError) {
  create_with_decoder(client, request, response.decode_response())
}

pub fn create_with_decoder(
  client client: Client,
  request request: CreateResponse,
  decoder decoder: Decoder(a),
) -> Result(a, OpenAIError) {
  let body =
    response.encode_create_response(request)
    |> json.to_string

  use resp <- result.try(client.send_text(
    client,
    transport.Post,
    responses_url,
    [#("Content-Type", "application/json")],
    body,
    Some(90_000),
  ))

  use result <- result.try(
    json.parse(resp, decoder)
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}

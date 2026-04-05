import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import openai/audio
import openai/client
import openai/completions
import openai/embeddings
import openai/error
import openai/responses
import openai/transport
import openai/types/audio/transcription
import openai/types/audio/translation
import openai/types/completion
import openai/types/embedding
import openai/types/models
import openai/types/responses/compaction
import openai/types/responses/reasoning
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tool_choice
import openai/types/responses/tools/function
import openai/types/responses/tools/shell
import openai/types/responses/tools/web_search
import openai/types/role.{System, User}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn model_string_conversion_test() {
  assert models.embedding_model_to_string(models.TextEmbedding3Small)
    == "text-embedding-3-small"
  assert models.embedding_model_from_string("text-embedding-3-small")
    == models.TextEmbedding3Small

  assert models.response_model_to_string(models.GPT5Mini) == "gpt-5-mini"
  assert models.response_model_from_string("gpt-5-mini") == models.GPT5Mini

  assert models.audio_model_to_string(models.Gpt4oTranscribe)
    == "gpt-4o-transcribe"
  assert models.audio_model_from_string("gpt-4o-transcribe")
    == models.Gpt4oTranscribe
}

pub fn audio_request_builder_defaults_test() {
  let transcription_request = transcription.new()
  let translation_request = translation.new()

  assert transcription_request.model == "gpt-4o-transcribe"
  assert translation_request.model == "whisper-1"
}

pub fn web_search_call_without_action_decoding_test() {
  let body =
    "
{
  \"id\": \"ws_123\",
  \"status\": \"completed\"
}
"

  let assert Ok(decoded) = json.parse(body, web_search.decode_web_search_call())

  assert decoded
    == web_search.WebSearchCall(
      id: "ws_123",
      action: None,
      status: web_search.Completed,
    )
}

pub fn shell_call_response_decoding_test() {
  let body =
    "
{
  \"id\": \"resp_0a2a88d6c4c76aec0069cc64b8f7cc819982052c55f30586ea\",
  \"object\": \"response\",
  \"created_at\": 1775002808,
  \"status\": \"completed\",
  \"background\": false,
  \"billing\": {
    \"payer\": \"developer\"
  },
  \"completed_at\": 1775002809,
  \"error\": null,
  \"frequency_penalty\": 0.0,
  \"incomplete_details\": null,
  \"instructions\": \"The local bash environment is on macOS\",
  \"max_output_tokens\": null,
  \"max_tool_calls\": null,
  \"model\": \"gpt-5.4-2026-03-05\",
  \"output\": [
    {
      \"id\": \"sh_0a2a88d6c4c76aec0069cc64b999c88199ac9eac076be5035d\",
      \"type\": \"shell_call\",
      \"status\": \"completed\",
      \"action\": {
        \"commands\": [
          \"pwd\"
        ],
        \"max_output_length\": 2000,
        \"timeout_ms\": 5000
      },
      \"call_id\": \"call_8jOUBXx3d9tmpC1un3Nhun03\",
      \"environment\": null
    }
  ],
  \"parallel_tool_calls\": true,
  \"presence_penalty\": 0.0,
  \"previous_response_id\": null,
  \"prompt_cache_key\": null,
  \"prompt_cache_retention\": null,
  \"reasoning\": {
    \"effort\": \"none\",
    \"summary\": null
  },
  \"safety_identifier\": null,
  \"service_tier\": \"default\",
  \"store\": true,
  \"temperature\": 1.0,
  \"text\": {
    \"format\": {
      \"type\": \"text\"
    },
    \"verbosity\": \"medium\"
  },
  \"tool_choice\": \"auto\",
  \"tools\": [
    {
      \"type\": \"shell\",
      \"environment\": {
        \"type\": \"local\"
      }
    }
  ],
  \"top_logprobs\": 0,
  \"top_p\": 0.98,
  \"truncation\": \"disabled\",
  \"usage\": {
    \"input_tokens\": 259,
    \"input_tokens_details\": {
      \"cached_tokens\": 0
    },
    \"output_tokens\": 30,
    \"output_tokens_details\": {
      \"reasoning_tokens\": 0
    },
    \"total_tokens\": 289
  },
  \"user\": null,
  \"metadata\": {}
}
"

  let assert Ok(decoded) = json.parse(body, response.decode_response())
  let assert [response.ShellCallItem(shell_call)] = decoded.output
  assert shell_call
    == shell.ShellCall(
      id: "sh_0a2a88d6c4c76aec0069cc64b999c88199ac9eac076be5035d",
      action: shell.Action(
        commands: ["pwd"],
        max_output_length: Some(2000),
        timeout_ms: Some(5000),
      ),
      call_id: "call_8jOUBXx3d9tmpC1un3Nhun03",
      status: shell.Completed,
    )
  let assert [tool.ShellTool(shell_tool)] = decoded.tools
  assert shell_tool
    == shell.Shell(
      environment: Some(
        shell.LocalEnvironmentItem(shell.LocalEnvironment(skills: None)),
      ),
    )
}

pub fn create_embedding_request_encoding_test() {
  let request =
    embedding.EmbeddingCreateParams(
      input: embedding.StringList(["The food was delicious and the waiter..."]),
      model: "text-embedding-3-small",
      dimensions: Some(256),
      encoding_format: Some(embedding.Float),
      user: Some("sdk-user"),
    )

  let encoded =
    embedding.encode_embedding_create_params(request)
    |> json.to_string

  assert encoded
    == "{\"user\":\"sdk-user\",\"dimensions\":256,\"encoding_format\":\"float\",\"input\":[\"The food was delicious and the waiter...\"],\"model\":\"text-embedding-3-small\"}"
}

pub fn create_embedding_response_decoding_test() {
  let body =
    "
{
  \"object\": \"list\",
  \"data\": [
    {
      \"object\": \"embedding\",
      \"embedding\": [0.1, 0.2, 0.3],
      \"index\": 0
    }
  ],
  \"model\": \"text-embedding-3-small\",
  \"usage\": {
    \"prompt_tokens\": 8,
    \"total_tokens\": 8
  }
}
"

  let assert Ok(decoded) =
    json.parse(body, embedding.decode_create_embedding_response())

  let embedding.CreateEmbeddingResponse(data:, model:, usage:) = decoded
  assert model == "text-embedding-3-small"
  assert list.length(data) == 1
  assert usage == embedding.Usage(prompt_tokens: 8, total_tokens: 8)
}

pub fn embeddings_create_uses_client_transport_test() {
  let expected_request =
    "{\"encoding_format\":\"float\",\"input\":[\"hello world\"],\"model\":\"text-embedding-ada-002\"}"

  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/embeddings"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #("Content-Type", "application/json"),
        ]
      assert body == transport.Text(expected_request)
      assert timeout_ms == None

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Text(
          "{\"object\":\"list\",\"data\":[{\"object\":\"embedding\",\"embedding\":[0.1,0.2],\"index\":0}],\"model\":\"text-embedding-3-small\",\"usage\":{\"prompt_tokens\":4,\"total_tokens\":4}}",
        ),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let request =
    embedding.new()
    |> embedding.with_input(embedding.StringList(["hello world"]))
    |> embedding.with_encoding_format(embedding.Float)

  let assert Ok(response) = embeddings.create(client, request)

  assert response.model == "text-embedding-3-small"
  assert response.usage == embedding.Usage(prompt_tokens: 4, total_tokens: 4)
}

pub fn client_send_text_maps_http_errors_test() {
  let invalid_request_client =
    client.new_with_transport("test-key", status_transport(400))
  let auth_client = client.new_with_transport("test-key", status_transport(401))
  let not_found_client =
    client.new_with_transport("test-key", status_transport(404))
  let rate_limit_client =
    client.new_with_transport("test-key", status_transport(429))
  let internal_server_client =
    client.new_with_transport("test-key", status_transport(500))

  assert client.send_text(
      invalid_request_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.InvalidRequest("request failed"))

  assert client.send_text(
      auth_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.Authentication("request failed"))

  assert client.send_text(
      not_found_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.NotFound("request failed"))

  assert client.send_text(
      rate_limit_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.RateLimit("request failed"))

  assert client.send_text(
      internal_server_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.InternalServer("request failed"))
}

pub fn client_send_text_handles_bad_error_json_and_byte_bodies_test() {
  let bad_error_json_client =
    client.new_with_transport(
      "test-key",
      transport.new_transport(fn(_req) {
        Ok(transport.TransportResponse(
          status: 400,
          headers: [],
          body: transport.Text("{\"error\":{}}"),
        ))
      }),
    )

  let byte_response_client =
    client.new_with_transport(
      "test-key",
      transport.new_transport(fn(_req) {
        Ok(transport.TransportResponse(
          status: 200,
          headers: [],
          body: transport.Bytes(bit_array.from_string("{\"ok\":true}")),
        ))
      }),
    )

  assert client.send_text(
      bad_error_json_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Error(error.BadResponse)

  assert client.send_text(
      byte_response_client,
      transport.Post,
      "https://example.test",
      [],
      "{}",
      None,
    )
    == Ok("{\"ok\":true}")
}

pub fn audio_create_transcription_uses_client_transport_test() {
  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/audio/transcriptions"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #(
            "Content-Type",
            "multipart/form-data; boundary=----OpenAIAudioBoundary",
          ),
        ]
      assert timeout_ms == Some(90_000)

      let assert transport.Bytes(body_bytes) = body
      assert bit_array.byte_size(body_bytes) > 0
      let assert Ok(prefix) = bit_array.slice(body_bytes, 0, 180)
      let assert Ok(body_text) = bit_array.to_string(prefix)
      assert string.contains(body_text, "name=\"model\"")
      assert string.contains(body_text, "gpt-4o-transcribe")
      assert string.contains(body_text, "filename=\"tran")

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Text(
          "{\"text\":\"hello there\",\"usage\":{\"type\":\"duration\",\"seconds\":3}}",
        ),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let request =
    transcription.new()
    |> transcription.with_file(
      "examples/transcription_10/audio/transcription.m4a",
    )

  let assert Ok(response) = audio.create_transcription(client, request)
  assert response.text == "hello there"
  assert response.usage
    == transcription.DurationUsage(transcription.DurationUsageDef(seconds: 3))
}

pub fn audio_create_translation_accepts_byte_transport_response_test() {
  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/audio/translations"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #(
            "Content-Type",
            "multipart/form-data; boundary=----OpenAIAudioBoundary",
          ),
        ]
      assert timeout_ms == Some(90_000)

      let assert transport.Bytes(body_bytes) = body
      assert bit_array.byte_size(body_bytes) > 0
      let assert Ok(prefix) = bit_array.slice(body_bytes, 0, 180)
      let assert Ok(body_text) = bit_array.to_string(prefix)
      assert string.contains(body_text, "name=\"model\"")
      assert string.contains(body_text, "whisper-1")
      assert string.contains(body_text, "filename=\"japanese_spe")

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Bytes(bit_array.from_string("{\"text\":\"translated\"}")),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let request =
    translation.new()
    |> translation.with_file(
      "examples/translation_11/audio/japanese_speech.m4a",
    )

  let assert Ok(response) = audio.create_translation(client, request)
  assert response.text == "translated"
}

pub fn responses_create_uses_client_transport_test() {
  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/responses"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #("Content-Type", "application/json"),
        ]
      assert timeout_ms == Some(90_000)
      assert body == transport.Text(response_request_body())

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Text(valid_response_body()),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let request =
    responses.new()
    |> responses.with_model("gpt-5-mini")
    |> responses.with_input(response.Text("Give me two fun facts about Gleam."))

  let assert Ok(api_response) = responses.create(client, request)
  assert api_response.id
    == "resp_0a2a88d6c4c76aec0069cc64b8f7cc819982052c55f30586ea"
  assert api_response.model == "gpt-5.4-2026-03-05"
  let assert [response.ShellCallItem(shell_call)] = api_response.output
  assert shell_call.status == shell.Completed
}

pub fn completions_create_uses_client_transport_test() {
  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/chat/completions"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #("Content-Type", "application/json"),
        ]
      assert body == transport.Text(completion_request_body(False))
      assert timeout_ms == None

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Text(chat_completion_response_body()),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let config = completion.new()
  let messages = completion_messages()

  let assert Ok(response) = completions.create(client, config, messages)

  assert response.model == "gpt-5.2"
  assert response.service_tier == "default"
  let assert [choice] = response.choices
  assert choice.message.content == "Streaming is working."
}

pub fn completions_create_with_decoder_uses_client_transport_test() {
  let fake_transport =
    transport.new_transport(fn(req) {
      let transport.TransportRequest(method, url, headers, body, timeout_ms) =
        req

      assert method == transport.Post
      assert url == "https://api.openai.com/v1/chat/completions"
      assert headers
        == [
          #("Authorization", "Bearer test-key"),
          #("Content-Type", "application/json"),
        ]
      assert body == transport.Text(completion_request_body(False))
      assert timeout_ms == None

      Ok(transport.TransportResponse(
        status: 200,
        headers: [],
        body: transport.Text(chat_completion_response_body()),
      ))
    })

  let client = client.new_with_transport("test-key", fake_transport)
  let config = completion.new()
  let messages = completion_messages()

  let assert Ok(text) =
    completions.create_with_decoder(
      client,
      config,
      messages,
      decode_first_chat_completion_text(),
    )

  assert text == "Streaming is working."
}

pub fn completions_create_rejects_streaming_config_test() {
  let client =
    client.new_with_transport(
      "test-key",
      transport.new_transport(fn(_req) { Error(error.Unknown) }),
    )
  let config =
    completion.CompletionCreateParams(..completion.new(), stream: True)

  assert completions.create(client, config, completion_messages())
    == Error(error.InvalidRequest(
      "completions.create requires config.stream to be False",
    ))
}

pub fn create_chat_completion_response_decoding_with_missing_optional_fields_test() {
  let body =
    "
{
  \"object\": \"chat.completion\",
  \"id\": \"chatcmpl-abc123\",
  \"model\": \"gpt-4o-2024-08-06\",
  \"created\": 1738960610,
  \"usage\": {
    \"total_tokens\": 31,
    \"completion_tokens\": 18,
    \"prompt_tokens\": 13
  },
  \"choices\": [
    {
      \"index\": 0,
      \"message\": {
        \"content\": \"Mind of circuits hum\",
        \"role\": \"assistant\",
        \"tool_calls\": null,
        \"function_call\": null
      },
      \"finish_reason\": \"stop\",
      \"logprobs\": null
    }
  ]
}
"

  let assert Ok(decoded) = json.parse(body, completion.decode_chat_completion())
  let assert [choice] = decoded.choices

  assert decoded.service_tier == "default"
  assert decoded.system_fingerprint == None
  assert choice.message.annotations == []
  assert choice.message.content == "Mind of circuits hum"
  assert decoded.usage.prompt_tokens_details
    == completion.PromptTokenDetails(cached_tokens: 0, audio_tokens: 0)
}

pub fn decode_first_completion_chunk_text_test() {
  let body =
    "
{
  \"id\": \"chatcmpl-123\",
  \"object\": \"chat.completion.chunk\",
  \"created\": 1710000000,
  \"model\": \"gpt-5.2\",
  \"choices\": [
    {
      \"index\": 0,
      \"delta\": {
        \"role\": \"assistant\",
        \"content\": \"Hello\"
      },
      \"finish_reason\": null
    }
  ],
  \"system_fingerprint\": null
}
"

  let assert Ok(decoded) =
    json.parse(body, decode_first_completion_chunk_text())

  assert decoded == "Hello"
}

fn decode_first_chat_completion_text() -> decode.Decoder(String) {
  let decode_first_choice = fn() {
    use content <- decode.subfield(["message", "content"], decode.string)
    decode.success(content)
  }

  decode.at(["choices"], decode.at([0], decode_first_choice()))
}

fn decode_first_completion_chunk_text() -> decode.Decoder(String) {
  let decode_first_choice = fn() {
    use content <- decode.subfield(["delta", "content"], decode.string)
    decode.success(content)
  }

  decode.at(["choices"], decode.at([0], decode_first_choice()))
}

pub fn completions_stream_create_uses_stream_transport_test() {
  let fake_transport =
    transport.new_transport_with_stream(
      fn(_req) { Error(error.Unknown) },
      fn(req) {
        let transport.TransportRequest(method, url, headers, body, timeout_ms) =
          req

        assert method == transport.Post
        assert url == "https://api.openai.com/v1/chat/completions"
        assert headers
          == [
            #("Authorization", "Bearer test-key"),
            #("accept", "text/event-stream"),
            #("Content-Type", "application/json"),
          ]
        assert body == transport.Text(completion_request_body(True))
        assert timeout_ms == None

        let subject = process.new_subject()
        process.send(subject, transport.StreamStart)
        process.send(
          subject,
          transport.StreamChunk(bit_array.from_string(
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1710000000,\"model\":\"gpt-5.2\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"Hello\"},\"finish_reason\":null}],\"system_fingerprint\":null}\n\n",
          )),
        )
        process.send(
          subject,
          transport.StreamChunk(bit_array.from_string("data: [DONE]\n\n")),
        )

        Ok(
          transport.new_stream(fn(timeout_ms) {
            process.receive(subject, within: timeout_ms)
            |> result.replace_error(error.Timeout)
          }),
        )
      },
    )

  let client = client.new_with_transport("test-key", fake_transport)
  let config =
    completion.CompletionCreateParams(..completion.new(), stream: True)
  let messages = completion_messages()

  let assert Ok(handler) = completions.stream_create(client, config, messages)
  let assert Ok(completions.StreamStart(handler)) =
    completions.stream_create_handler(handler)
  let assert Ok(completions.StreamChunk(chunks)) =
    completions.stream_create_handler(handler)
  let assert [chunk] = chunks
  let assert [choice] = chunk.choices
  assert choice.delta.content == "Hello"
  assert choice.delta.role == "assistant"
  assert completions.stream_create_handler(handler) == Ok(completions.StreamEnd)
}

pub fn completions_stream_create_handler_with_decoder_test() {
  let fake_transport =
    transport.new_transport_with_stream(
      fn(_req) { Error(error.Unknown) },
      fn(_req) {
        let subject = process.new_subject()
        process.send(subject, transport.StreamStart)
        process.send(
          subject,
          transport.StreamChunk(bit_array.from_string(
            "data: {\"id\":\"chatcmpl-123\",\"object\":\"chat.completion.chunk\",\"created\":1710000000,\"model\":\"gpt-5.2\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"Hello\"},\"finish_reason\":null}],\"system_fingerprint\":null}\n\n",
          )),
        )
        process.send(
          subject,
          transport.StreamChunk(bit_array.from_string("data: [DONE]\n\n")),
        )

        Ok(
          transport.new_stream(fn(timeout_ms) {
            process.receive(subject, within: timeout_ms)
            |> result.replace_error(error.Timeout)
          }),
        )
      },
    )

  let client = client.new_with_transport("test-key", fake_transport)
  let config =
    completion.CompletionCreateParams(..completion.new(), stream: True)
  let messages = completion_messages()

  let assert Ok(handler) = completions.stream_create(client, config, messages)
  let assert Ok(completions.DecodedStreamStart(handler)) =
    completions.stream_create_handler_with_decoder(
      handler,
      completion.decode_completion_chunk(),
    )
  let assert Ok(completions.DecodedStreamChunk(chunks)) =
    completions.stream_create_handler_with_decoder(
      handler,
      completion.decode_completion_chunk(),
    )
  let assert [chunk] = chunks
  let assert [choice] = chunk.choices
  assert choice.delta.content == "Hello"
  assert completions.stream_create_handler_with_decoder(
      handler,
      completion.decode_completion_chunk(),
    )
    == Ok(completions.DecodedStreamEnd)
}

pub fn completions_stream_create_rejects_non_streaming_config_test() {
  let client =
    client.new_with_transport(
      "test-key",
      transport.new_transport_with_stream(
        fn(_req) { Error(error.Unknown) },
        fn(_req) { Error(error.Unknown) },
      ),
    )

  assert completions.stream_create(
      client,
      completion.new(),
      completion_messages(),
    )
    == Error(error.InvalidRequest(
      "completions.stream_create requires config.stream to be True",
    ))
}

fn status_transport(status: Int) -> transport.Transport {
  transport.new_transport(fn(_req) {
    Ok(transport.TransportResponse(
      status: status,
      headers: [],
      body: transport.Text("{\"error\":{\"message\":\"request failed\"}}"),
    ))
  })
}

fn completion_messages() -> List(completion.Message) {
  completions.add_message([], System, "You are a helpful assistant")
  |> completions.add_message(User, "Explain streaming briefly.")
}

fn completion_request_body(stream: Bool) -> String {
  "{\"model\":\"gpt-5.2\",\"temperature\":0.7,\"stream\":"
  <> case stream {
    True -> "true"
    False -> "false"
  }
  <> ",\"messages\":[{\"role\":\"system\",\"content\":\"You are a helpful assistant\"},{\"role\":\"user\",\"content\":\"Explain streaming briefly.\"}]}"
}

fn chat_completion_response_body() -> String {
  "{\"id\":\"chatcmpl-123\",\"object\":\"chat.completion\",\"created\":1710000000,\"choices\":[{\"finish_reason\":\"stop\",\"index\":0,\"logprobs\":null,\"message\":{\"role\":\"assistant\",\"content\":\"Streaming is working.\",\"refusal\":null,\"annotations\":[],\"tool_calls\":null}}],\"usage\":{\"completion_tokens\":4,\"prompt_tokens\":8,\"total_tokens\":12,\"prompt_tokens_details\":{\"cached_tokens\":0,\"audio_tokens\":0},\"completion_tokens_details\":{\"accepted_prediction_tokens\":0,\"audio_tokens\":0,\"reasoning_tokens\":0,\"rejected_prediction_tokens\":0}},\"model\":\"gpt-5.2\",\"service_tier\":\"default\",\"system_fingerprint\":null}"
}

fn response_request_body() -> String {
  "{\"model\":\"gpt-5-mini\",\"input\":\"Give me two fun facts about Gleam.\"}"
}

fn valid_response_body() -> String {
  "
{
  \"id\": \"resp_0a2a88d6c4c76aec0069cc64b8f7cc819982052c55f30586ea\",
  \"object\": \"response\",
  \"created_at\": 1775002808,
  \"status\": \"completed\",
  \"background\": false,
  \"billing\": {
    \"payer\": \"developer\"
  },
  \"completed_at\": 1775002809,
  \"error\": null,
  \"frequency_penalty\": 0.0,
  \"incomplete_details\": null,
  \"instructions\": \"The local bash environment is on macOS\",
  \"max_output_tokens\": null,
  \"max_tool_calls\": null,
  \"model\": \"gpt-5.4-2026-03-05\",
  \"output\": [
    {
      \"id\": \"sh_0a2a88d6c4c76aec0069cc64b999c88199ac9eac076be5035d\",
      \"type\": \"shell_call\",
      \"status\": \"completed\",
      \"action\": {
        \"commands\": [
          \"pwd\"
        ],
        \"max_output_length\": 2000,
        \"timeout_ms\": 5000
      },
      \"call_id\": \"call_8jOUBXx3d9tmpC1un3Nhun03\",
      \"environment\": null
    }
  ],
  \"parallel_tool_calls\": true,
  \"presence_penalty\": 0.0,
  \"previous_response_id\": null,
  \"prompt_cache_key\": null,
  \"prompt_cache_retention\": null,
  \"reasoning\": {
    \"effort\": \"none\",
    \"summary\": null
  },
  \"safety_identifier\": null,
  \"service_tier\": \"default\",
  \"store\": true,
  \"temperature\": 1.0,
  \"text\": {
    \"format\": {
      \"type\": \"text\"
    },
    \"verbosity\": \"medium\"
  },
  \"tool_choice\": \"auto\",
  \"tools\": [
    {
      \"type\": \"shell\",
      \"environment\": {
        \"type\": \"local\"
      }
    }
  ],
  \"top_logprobs\": 0,
  \"top_p\": 0.98,
  \"truncation\": \"disabled\",
  \"usage\": {
    \"input_tokens\": 259,
    \"input_tokens_details\": {
      \"cached_tokens\": 0
    },
    \"output_tokens\": 30,
    \"output_tokens_details\": {
      \"reasoning_tokens\": 0
    },
    \"total_tokens\": 289
  },
  \"user\": null,
  \"metadata\": {}
}
"
}

pub fn create_response_json_encoding_test() {
  let text_config =
    response.new_text_param()
    |> response.text_format(response.ResponseFormatText)

  let request =
    response.CreateResponse(
      background: Some(True),
      context_management: Some(compaction.ContextManagement(
        type_: compaction.ContextManagementType,
        compact_threshold: 2048,
      )),
      include: Some([
        response.FileSearchCallResults,
        response.WebSearchCallResults,
      ]),
      input: response.Text("Summarize this"),
      instructions: Some("Be concise"),
      max_output_tokens: Some(256),
      max_tool_calls: Some(3),
      metadata: Some([]),
      model: "gpt-5-mini",
      parallel_tool_calls: Some(True),
      prompt: None,
      prompt_cache_key: Some("cache-key"),
      prompt_cache_retention: Some(response.Hours24),
      reasoning: Some(reasoning.ReasoningDef(
        effort: Some(reasoning.Low),
        summary: Some(reasoning.Concise),
      )),
      safety_identifier: Some("safe-user-1"),
      service_tier: Some(response.Flex),
      store: Some(False),
      stream_options: Some(response.StreamOptions(include_obfuscation: False)),
      text: Some(text_config),
      top_logprobs: Some(2),
      top_p: Some(0.9),
      truncation: Some(response.Auto),
      temperature: Some(0.2),
      stream: Some(True),
      conversation_context: None,
      tool_choice: Some(tool_choice.options("required")),
      tools: Some([
        tool.FunctionTool(function.Function(
          name: "weather_lookup",
          description: Some("Look up the weather for a city"),
          parameters: json.object([
            #("type", json.string("object")),
            #(
              "properties",
              json.object([
                #("city", json.object([#("type", json.string("string"))])),
              ]),
            ),
            #("required", json.array(["city"], json.string)),
          ]),
          strict: True,
          defer_loading: None,
        )),
        tool.WebSearchTool(web_search.new_web_search()),
      ]),
    )

  let encoded =
    response.encode_create_response(request)
    |> json.to_string

  assert string.contains(encoded, "\"model\":\"gpt-5-mini\"")
  assert string.contains(encoded, "\"stream\":true")
  assert string.contains(encoded, "\"tool_choice\":\"required\"")
}

pub fn response_full_decoding_test() {
  let body =
    "
{
  \"id\": \"resp_09d047ce2d7360ba0069b0aeb39e908196a67f5db65e6e8839\",
  \"object\": \"response\",
  \"created_at\": 1773186739,
  \"status\": \"completed\",
  \"background\": false,
  \"billing\": {
    \"payer\": \"developer\"
  },
  \"completed_at\": 1773186748,
  \"conversation\": null,
  \"error\": null,
  \"frequency_penalty\": 0.0,
  \"incomplete_details\": null,
  \"instructions\": null,
  \"max_output_tokens\": null,
  \"max_tool_calls\": null,
  \"metadata\": {},
  \"model\": \"gpt-5.1-2025-11-13\",
  \"output\": [],
  \"output_text\": null,
  \"parallel_tool_calls\": true,
  \"presence_penalty\": 0.0,
  \"previous_response_id\": null,
  \"prompt\": null,
  \"prompt_cache_key\": null,
  \"prompt_cache_retention\": null,
  \"reasoning\": {
    \"effort\": \"medium\",
    \"summary\": null
  },
  \"safety_identifier\": null,
  \"service_tier\": \"default\",
  \"store\": true,
  \"temperature\": 1.0,
  \"text\": {
    \"format\": {
      \"type\": \"text\"
    },
    \"verbosity\": \"medium\"
  },
  \"tool_choice\": \"auto\",
  \"tools\": [
    {
      \"type\": \"web_search_preview\",
      \"search_context_size\": \"medium\",
      \"user_location\": {
        \"type\": \"approximate\",
        \"city\": null,
        \"country\": \"US\",
        \"region\": null,
        \"timezone\": null
      }
    }
  ],
  \"top_p\": 1.0,
  \"top_logprobs\": 2,
  \"truncation\": \"disabled\",
  \"usage\": {
    \"input_tokens\": 10328,
    \"input_tokens_details\": {
      \"cached_tokens\": 0
    },
    \"output_tokens\": 750,
    \"output_tokens_details\": {
      \"reasoning_tokens\": 37
    },
    \"total_tokens\": 11078
  },
  \"user\": null,
  \"metadata\": {}
}
"

  let assert Ok(decoded) = json.parse(body, response.decode_response())

  let response.Response(
    id: id,
    created_at: created_at,
    error: error,
    incomplete_details: incomplete_details,
    instructions: instructions,
    metadata: metadata,
    model: model,
    object: object,
    output: output,
    parallel_tool_calls: parallel_tool_calls,
    temperature: temperature,
    tool_choice: tool_choice_value,
    tools: response_tools,
    top_p: top_p,
    background: background,
    completed_at: completed_at,
    conversation: conversation,
    max_output_tokens: max_output_tokens,
    max_tool_calls: max_tool_calls,
    output_text: output_text,
    previous_response_id: previous_response_id,
    prompt: prompt,
    prompt_cache_key: prompt_cache_key,
    prompt_cache_retention: prompt_cache_retention,
    reasoning: reasoning,
    safety_identifier: safety_identifier,
    service_tier: service_tier,
    status: status,
    text: text,
    top_logprobs: top_logprobs,
    truncation: truncation,
    billing: billing,
    store: store,
    usage: usage,
  ) = decoded

  assert id == "resp_09d047ce2d7360ba0069b0aeb39e908196a67f5db65e6e8839"
  assert created_at == 1_773_186_739
  assert error == None
  assert incomplete_details == None
  assert instructions == None
  assert model == "gpt-5.1-2025-11-13"
  assert object == "response"
  assert parallel_tool_calls
  assert temperature == 1.0
  assert tool_choice_value == tool_choice.Options(tool_choice.Auto)
  assert list.length(response_tools) == 1
  assert top_p == 1.0
  assert !background
  assert completed_at == Some(1_773_186_748.0)
  assert conversation == None
  assert max_output_tokens == None
  assert max_tool_calls == None
  assert output_text == None
  assert previous_response_id == None
  assert prompt == None
  assert prompt_cache_key == None
  assert prompt_cache_retention == None
  assert safety_identifier == None
  assert service_tier == "default"
  assert status == response.Completed
  assert top_logprobs == 2
  assert truncation == "disabled"
  assert billing == response.Billing(payer: "developer")
  assert store
  assert usage
    == Some(response.Usage(
      input_tokens: 10_328,
      input_tokens_details: response.InputTokensDetails(cached_tokens: 0),
      output_tokens: 750,
      output_tokens_details: response.OutputTokensDetails(reasoning_tokens: 37),
      total_tokens: 11_078,
    ))
  assert metadata == Some([])
  assert output == []
  let reasoning.ReasoningDef(effort:, summary:) = reasoning
  assert effort == Some(reasoning.Medium)
  assert summary == None
  assert reasoning
    == reasoning.ReasoningDef(effort: Some(reasoning.Medium), summary: None)
  assert text == Some(response.ResponseFormatText)
}

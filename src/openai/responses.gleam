import gleam/http
import gleam/http/request as http_request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import openai/error
import openai/responses/decoders
import openai/responses/encoders
import openai/responses/types/request.{type Request, Request}
import openai/responses/types/response.{type Response}
import openai/types as shared

const responses_url = "https://api.openai.com/v1/responses"

pub fn default_request() -> Request {
  Request(
    model: shared.GPT41Mini,
    input: request.InputText(""),
    instructions: None,
    temperature: None,
    stream: None,
    tool_choice: None,
    tools: None,
  )
}

pub fn model(config: Request, model: shared.Model) {
  Request(..config, model:)
}

pub fn input(config: Request, input: request.Input) -> Request {
  Request(..config, input:)
}

pub fn instructions(config: Request, instructions: Option(String)) -> Request {
  Request(..config, instructions:)
}

pub fn tool_choice(config: Request, tool_choice: request.ToolChoice) {
  Request(..config, tool_choice: Some(tool_choice))
}

pub fn tools(
  config: Request,
  tools: Option(List(request.Tools)),
  tool: request.Tools,
) {
  case tools {
    None -> Request(..config, tools: Some([tool]))
    Some(ts) -> Request(..config, tools: Some(list.prepend(ts, tool)))
  }
}

pub fn create(
  client client: String,
  request config: Request,
) -> Result(Response, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = http_request.to(responses_url)

  let body =
    encoders.config_encoder(config)
    |> json.to_string
  // |> echo

  let req =
    base_req
    |> http_request.prepend_header("Content-Type", "application/json")
    |> http_request.prepend_header("Authorization", "Bearer " <> client)
    |> http_request.set_body(body)
    |> http_request.set_method(http.Post)

  use resp <- result.try(
    httpc.configure()
    |> httpc.timeout(90_000)
    |> httpc.dispatch(req)
    |> error.replace_error(),
  )
  use result <- result.try(
    json.parse(resp.body, decoders.response_decoder())
    // |> echo
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}
// "{\n  \"output\": [\n    {\n      \"id\": \"mcpl_0f2949b33cb2d9b800690a8bad50748194adc6d5ca88c3dbae\",\n      \"type\": \"mcp_list_tools\",\n      \"server_label\": \"deepwiki\",\n      \"tools\": [\n        {\n          \"annotations\": {\n            \"read_only\": false\n          },\n          \"description\": \"Get a list of documentation topics for a GitHub repository\",\n          \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\n              \"repoName\": {\n                \"type\": \"string\",\n                \"description\": \"GitHub repository: owner/repo (e.g. \\\"facebook/react\\\")\"\n              }\n            },\n            \"required\": [\n              \"repoName\"\n            ],\n            \"additionalProperties\": false,\n            \"$schema\": \"http://json-schema.org/draft-07/schema#\"\n          },\n          \"name\": \"read_wiki_structure\"\n        },\n        {\n          \"annotations\": {\n            \"read_only\": false\n          },\n          \"description\": \"View documentation about a GitHub repository\",\n          \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\n              \"repoName\": {\n                \"type\": \"string\",\n                \"description\": \"GitHub repository: owner/repo (e.g. \\\"facebook/react\\\")\"\n              }\n            },\n            \"required\": [\n              \"repoName\"\n            ],\n            \"additionalProperties\": false,\n            \"$schema\": \"http://json-schema.org/draft-07/schema#\"\n          },\n          \"name\": \"read_wiki_contents\"\n        },\n        {\n          \"annotations\": {\n            \"read_only\": false\n          },\n          \"description\": \"Ask any question about a GitHub repository\",\n          \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\n              \"repoName\": {\n                \"type\": \"string\",\n                \"description\": \"GitHub repository: owner/repo (e.g. \\\"facebook/react\\\")\"\n              },\n              \"question\": {\n                \"type\": \"string\",\n                \"description\": \"The question to ask about the repository\"\n              }\n            },\n            \"required\": [\n              \"repoName\",\n              \"question\"\n            ],\n            \"additionalProperties\": false,\n            \"$schema\": \"http://json-schema.org/draft-07/schema#\"\n          },\n          \"name\": \"ask_question\"\n        }\n      ]\n    },\n    {\n      \"id\": \"rs_0f2949b33cb2d9b800690a8bafd4c8819482d5570064cccdd2\",\n      \"type\": \"reasoning\",\n      \"summary\": []\n    },\n    {\n      \"id\": \"mcp_0f2949b33cb2d9b800690a8bb19ae48194a350fb06a6bd36c3\",\n      \"type\": \"mcp_call\",\n      \"status\": \"completed\",\n      \"approval_request_id\": null,\n      \"arguments\": \"{\\\"repoName\\\":\\\"modelcontextprotocol/modelcontextprotocol\\\",\\\"question\\\":\\\"What transport protocols does the 2025-03-26 version of the MCP spec support?\\\"}\",\n      \"error\": null,\n      \"name\": \"ask_question\",\n      \"output\": \"The 2025-03-26 version of the Model Context Protocol (MCP) specification supports two primary transport protocols: `stdio` and `HTTP` . These transports manage the communication channels between MCP clients and servers .\\n\\n## Supported Transport Protocols\\n\\n### `stdio` Transport\\nThe `stdio` transport uses standard input/output streams for direct process communication . This is typically used for local processes running on the same machine, offering optimal performance without network overhead . For shutdown, the client initiates by closing its input stream to the server and then waiting for the server to exit .\\n\\n### `HTTP` Transport\\nThe `HTTP` transport, specifically referred to as \\\"Streamable HTTP\\\" in later versions, uses HTTP POST for client-to-server messages . It also supports optional Server-Sent Events (SSE) for streaming capabilities from the server to the client . This transport is designed for remote server communication and supports standard HTTP authentication methods, including OAuth 2.1  . Shutdown for HTTP transports is indicated by closing the associated HTTP connection(s) .\\n\\n## Protocol Versioning\\nThe protocol version `2025-03-26` is explicitly mentioned in the lifecycle specification for initialization requests and responses  . This version is considered a legacy version, with `2025-06-18` being the latest stable version  .\\n\\n## Notes\\nThe `docs/specification/draft/basic/transports.mdx` file mentions \\\"Streamable HTTP\\\" as replacing \\\"HTTP+SSE\\\" from protocol version `2024-11-05` . While this file is a draft, the `docs/docs/learn/architecture.mdx` file, which is part of the general architecture overview, confirms that \\\"Streamable HTTP transport\\\" is a supported mechanism, including Server-Sent Events . The `docs/sdk/java/mcp-client.mdx` also shows `HttpClientStreamableHttpTransport` and `HttpClientSseClientTransport` as client transport implementations  .\\n\\nWiki pages you might want to explore:\\n- [Overview (modelcontextprotocol/modelcontextprotocol)](/wiki/modelcontextprotocol/modelcontextprotocol#1)\\n- [SDK Reference (modelcontextprotocol/modelcontextprotocol)](/wiki/modelcontextprotocol/modelcontextprotocol#5)\\n\\nView this search on DeepWiki: https://deepwiki.com/search/what-transport-protocols-does_20e10dce-168e-4f64-b7c2-b5219fe8bc67\\n\",\n      \"server_label\": \"deepwiki\"\n    },\n    {\n      \"id\": \"rs_0f2949b33cb2d9b800690a8bbd715c8194980ea160645c2f93\",\n      \"type\": \"reasoning\",\n      \"summary\": []\n    },\n    {\n      \"id\": \"msg_0f2949b33cb2d9b800690a8bc3601c819484c6e2dfa1c45b2e\",\n      \"type\": \"message\",\n      \"status\": \"completed\",\n      \"content\": [\n        {\n          \"type\": \"output_text\",\n          \"annotations\": [],\n          \"logprobs\": [],\n          \"text\": \"The 2025-03-26 MCP spec supports two transports:\\n- stdio (process stdin/stdout)\\n- HTTP \\u201cStreamable HTTP\\u201d (client-to-server via HTTP POST, with optional Server-Sent Events for server-to-client streaming)\"\n        }\n      ],\n      \"role\": \"assistant\"\n    }\n  ],\n  \"parallel_tool_calls\": true,\n  \"previous_response_id\": null,\n  \"prompt_cache_key\": null,\n  \"prompt_cache_retention\": null,\n  \"reasoning\": {\n    \"effort\": \"medium\",\n    \"summary\": null\n  },\n  \"safety_identifier\": null,\n  \"service_tier\": \"default\",\n  \"store\": true,\n  \"temperature\": 1.0,\n  \"text\": {\n    \"format\": {\n      \"type\": \"text\"\n    },\n    \"verbosity\": \"medium\"\n  },\n  \"tool_choice\": \"auto\",\n  \"tools\": [\n    {\n      \"type\": \"mcp\",\n      \"allowed_tools\": null,\n      \"headers\": null,\n      \"require_approval\": {\n        \"always\": null,\n        \"never\": {\n          \"read_only\": null,\n          \"tool_names\": [\n            \"ask_question\",\n            \"read_wiki_structure\"\n          ]\n        }\n      },\n      \"server_description\": null,\n      \"server_label\": \"deepwiki\",\n      \"server_url\": \"https://mcp.deepwiki.com/mcp\"\n    }\n  ],\n  \"top_logprobs\": 0,\n  \"top_p\": 1.0,\n  \"truncation\": \"disabled\",\n  \"usage\": {\n    \"input_tokens\": 916,\n    \"input_tokens_details\": {\n      \"cached_tokens\": 0\n    },\n    \"output_tokens\": 427,\n    \"output_tokens_details\": {\n      \"reasoning_tokens\": 320\n    },\n    \"total_tokens\": 1343\n  },\n  \"user\": null,\n  \"metadata\": {}\n}")

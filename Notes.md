## Example Suggestions

Good additions would be:

  - examples/multi_tool_14
    Combine web_search, function, and shell in one conversation so users can see how to replay tool calls across hops.
  - examples/conversation_state_15
    Demonstrate previous_response_id or conversation continuation instead of manually rebuilding all prior items.
  - examples/reasoning_16
    Show how reasoning settings affect a Responses call and how reasoning items should be preserved across turns.
  - examples/file_search_17
    Upload files, attach file_search, and answer questions grounded in those files.
  - examples/image_generation_18
    Use the image tool end-to-end and save returned image data or IDs.
  - examples/error_handling_19
    Show idiomatic Gleam handling for invalid requests, missing API keys, decode failures, and tool-call branches that don’t match
    expectations.
  - examples/streaming_responses_20
    A true Responses API streaming example would be useful if the SDK supports it or plans to.
  - examples/skills_with_clarification_21
    A skill that asks for clarification when the input is ambiguous, which would be a good companion to skills_12.
  - examples/tool_approval_loop_22
    Show a model proposing a tool call, local code approving/executing it, then sending the output back for a final answer.

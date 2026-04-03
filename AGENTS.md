# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

`openai` is an SDK for the [OpenAI API](https://developers.openai.com/api/reference/) written in Gleam. It wraps this REST API with typed request/response
structures, streaming support, and helpful utilities so Gleam applications can call the Responses, Files, Chat Completions, and Embeddings endpoints without hand-
writing JSON plumbing.

## Best Coding Practices

### Documentation
- Documentation lines for public functions and public types are prefixed with '/// '
- Documentation lines for private functions, types, and todos are prefixed with '//'
- Todos are prefixed with '// TODO ' followed by the action
- If you reference a function in your documentation, then unless it's a foreign function (e.g., Erlang), use Gleam syntax, only

### Record Data Types
- If a field within a record references another record (i.e. parent -> child) , then place the child record below the parent record

### Encoders and Decoders (e.g., Json)
- In general, whenever possible, place an encoder or decoder function just below the type declaration (e.g., records)


### Development
When Git-based examples in the `openai/examples` directory are a blocker for local verification, but the example source itself is what you need to validate, do the following:

1. Temporarily replace `openai = { git = "https://github.com/adkelley/openai", ref = "main" }` with `openai = { path = "../.." }` in the example's `gleam.toml` file.
   You can use `sh scripts/set_example_openai_dep.sh local examples/<example_name>` to do this.
2. Run `gleam clean` in the example directory.
3. If `manifest.toml` still prevents dependency resolution, ask the user for approval before removing it because `rm` is a destructive command.
4. Run `gleam check` in the example directory.

Once verification succeeds, restore the original Git dependency in the example's `gleam.toml` file. You can use `sh scripts/set_example_openai_dep.sh git examples/<example_name>` to do this. Do not leave the example pointed at a local path unless the user explicitly asks for that change.

Essential Commands:

- `gleam --help` - Help for the given subcommands
- `gleam deps download` - Install dependencies
- `gleam format` - Format the code
- `gleam test` - Run all tests
- `gleam check` - Type check the current package

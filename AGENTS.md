# AGENTS.md

Guidance for working in this repository.

## Overview

`openai` is a Gleam SDK for the [OpenAI API](https://developers.openai.com/api/reference/). It provides typed requests and responses, streaming support, and helpers for Responses, Files, Chat Completions, Audio, and Embeddings.

## Conventions

- Public docs use `///`.
- Private docs and TODOs use `//`.
- TODOs use `// TODO ...`.
- When docs reference Gleam functions, use Gleam syntax unless the function is foreign.
- If a record field refers to another record type, place the child record below the parent.
- When practical, keep encoders and decoders close to the type they encode or decode.

## Example Verification

If an example depends on the published Git version of this package and that blocks local verification:

1. Point the example at the local checkout:
   `sh scripts/set_example_openai_dep.sh local examples/<example_name>`
2. Run `gleam clean` in the example directory.
3. If `manifest.toml` still blocks dependency resolution, ask before removing it.
4. Run `gleam check` in the example directory.
5. Restore the Git dependency when done:
   `sh scripts/set_example_openai_dep.sh git examples/<example_name>`

Do not leave an example pointed at the local path unless the user asked for that change.

## Useful Commands

- `gleam deps download`
- `gleam check`
- `gleam test`
- `gleam format`

## Commits

- Follow the commit message approach described in `docs/commit.md`
- Prefer commit messages in the form `<symbol> <scope> - <summary>`

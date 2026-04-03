# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

`openai` is an SDK for the OpenAI API written in Gleam. It wraps the REST APIs with
typed request/response structures, streaming support, and helpful utilities so
Gleam applications can call the Responses, Files, Chat Completions, and Embeddings
endpoints without hand-writing JSON plumbing.

## Best Coding Practices
### Documentation
- Documentation lines for public functions and public types are prefixed with '/// '
- Documentation lines for private functions and types are prefixed witn '//'
- Todos are prefixed witn '// TODO '


## Essential Commands

### Development
- `gleam deps download` - Install dependencies
- `gleam format` - Format the code
- `gleam test` - Run all tests

# files_api_05

This example demonstrates the Files API workflow end to end. It uploads the
bundled `mydata.jsonl` file, retrieves the remote metadata, downloads the file
contents, writes them to `mydata_download.jsonl`, lists recent `evals` files,
and then deletes the listed files.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Confirm that `mydata.jsonl` contains the data you want to upload.

## Running

```sh
gleam run
```

The example uses `file_create_params/3`, `create/2`, `retrieve/2`, `content/2`,
`list/2`, and `delete/2` from `openai/files`.

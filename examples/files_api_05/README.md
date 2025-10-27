# files_api_05

## Overview

This example walks through the core operations of the Files API in the
`openai` Gleam SDK. It uploads a JSONL dataset, fetches file metadata and
contents, persists a local copy, and then cleans up by deleting the uploaded
files.

## Prerequisites

- Set the `OPENAI_API_KEY` environment variable with a key that allows Files API
  access.
- Ensure the bundled `mydata.jsonl` sample file contains the data you want to
  upload.

## Running the example

```sh
gleam run
```

The program will:

1. Upload `mydata.jsonl` for `evals` use and print the returned file object.
2. Download the remote file contents and save them as `mydata_download.jsonl`.
3. List recent files scoped to the `evals` purpose and display the response.
4. Delete the listed files and show the deletion results.

Refer to `src/files_api_05.gleam` for inline comments describing each step and
for ideas on adapting the workflow to your own datasets.

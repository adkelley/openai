# transcription_10

This example sends a local audio file to the OpenAI transcription endpoint and
prints the returned transcript text.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Replace the filename in `src/transcription_10.gleam` if you want to
  transcribe a different local file.

## Running

```sh
gleam run
```

The example uses `audio.new_transcription/0`,
`transcription.file/2`, and `audio.create_transcription/2`.

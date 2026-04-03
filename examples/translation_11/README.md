# translation_11

This example sends a local audio file to the OpenAI translation endpoint and
prints the translated transcript text.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Replace the filename in `src/translation_11.gleam` if you want to translate a
  different local file.

## Running

```sh
gleam run
```

The example uses `audio.new_translation/0`, `translation.file/2`,
and `audio.create_translation/2`.

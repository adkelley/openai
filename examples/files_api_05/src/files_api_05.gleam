/// Demonstrates the Files API workflow: upload, inspect, download, list, and delete.
import envoy
import gleam/list
import openai/files
import simplifile

/// Uploads a JSONL file, retrieves its info and contents, and then cleans up the
/// uploaded resources.
pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let assert Ok(upload_file) =
    files.file_create_params(
      "./mydata.jsonl",
      files.Evals,
      files.expires_after_params(3600),
    )
    |> files.create(api_key, _)
    |> echo

  let assert Ok(_file_object) = files.retrieve(api_key, upload_file.id) |> echo
  let assert Ok(file_payload) = files.content(api_key, upload_file.id)
  let file_path = "./mydata_download.jsonl"
  let assert Ok(_) = file_path |> simplifile.write_bits(file_payload)

  let assert Ok(list_files) =
    files.file_list_defaults()
    |> files.file_list_limit(1)
    |> files.file_list_purpose(files.Evals)
    |> files.list(api_key, _)

  let deletion_status =
    list.map(list_files.data, fn(file) { files.delete(api_key, file.id) })
  echo deletion_status

  Nil
}

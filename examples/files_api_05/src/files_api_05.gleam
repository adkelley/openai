/// Demonstrates the Files API workflow: upload, inspect, download, list, and delete.
import gleam/list
import openai/client
import openai/files
import simplifile

/// Uploads a JSONL file, retrieves its info and contents, and then cleans up the
/// uploaded resources.
pub fn main() -> Nil {
  let assert Ok(client) = client.new()

  let assert Ok(upload_file) =
    files.new_file(
      "./mydata.jsonl",
      files.Evals,
      files.expires_after(3600),
    )
    |> files.create(client, _)
    |> echo

  let assert Ok(_file_object) = files.retrieve(client, upload_file.id) |> echo
  let assert Ok(file_payload) = files.content(client, upload_file.id)
  let file_path = "./mydata_download.jsonl"
  let assert Ok(_) = file_path |> simplifile.write_bits(file_payload)

  let assert Ok(list_files) =
    files.new_list()
    |> files.with_limit(1)
    |> files.with_purpose(files.Evals)
    |> files.list(client, _)

  let deletion_status =
    list.map(list_files.data, fn(file) { files.delete(client, file.id) })
  echo deletion_status

  Nil
}

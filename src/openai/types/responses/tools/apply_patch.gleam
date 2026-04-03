import gleam/json.{type Json}
import gleam/option.{type Option}

// import openai/types/responses/enums.{type Enum}

pub type ApplyPatchCall {
  ApplyPatchCall(
    /// The ID of the apply patch tool call.
    call_id: String,
    /// The file operation requested by the tool call.
    operation: Operation,
    /// The status of the apply patch tool call.
    status: Status,
    /// The unique ID of the apply patch call item.
    id: Option(String),
    // type: "apply_patch_call"
  )
}

pub type Operation {
  CreateFileOperation(CreateFile)
  DeleteFileOperation(DeleteFile)
  UpdateFileOperation(UpdateFile)
}

pub type CreateFile {
  CreateFile(
    /// The diff used to create the file.
    diff: String,
    /// The path of the file to create.
    path: String,
    // type: "create_file"
  )
}

pub type DeleteFile {
  DeleteFile(
    /// The path of the file to delete.
    path: String,
    // type: "delete_file"
  )
}

pub type UpdateFile {
  UpdateFile(
    /// The diff used to update the file.
    diff: String,
    /// The path of the file to update.
    path: String,
    // type: "update_file"
  )
}

pub type Status {
  InProgress
  Completed
  Failed
}

pub type OutputStatus

pub type ApplyPatchCallOutput {
  ApplyPatchCallOutput(
    /// The ID of the apply patch tool call that produced the output.
    call_id: String,
    /// The status of the apply patch tool call output.
    status: Status,
    /// The unique ID of the apply patch output item.
    id: Option(String),
    // type: "apply_patch_call_output"
    /// Text output emitted by the apply patch tool call.
    output: Option(String),
  )
}

pub type ApplyPatch {
  ApplyPatch
}

pub fn encode_apply_patch() -> Json {
  json.object([#("type", json.string("apply_patch"))])
}

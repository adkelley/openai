import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}
import openai/types/helpers

pub type Compaction {
  Compaction(
    /// Encrypted content produced by the compaction API.
    encrypted_content: String,
    // type: "compaction"
    /// The unique ID of the compaction item.
    id: Option(String),
  )
}

pub fn encode_compaction(compaction: Compaction) -> Json {
  [
    #("type", json.string("compaction")),
    #("encrypted_content", json.string(compaction.encrypted_content)),
  ]
  |> helpers.encode_option("id", compaction.id, json.string)
  |> json.object
}

pub fn decode_compaction() -> Decoder(Compaction) {
  use encrypted_content <- decode.field("encrypted_content", decode.string)
  use id <- decode.field("id", decode.optional(decode.string))
  decode.success(Compaction(encrypted_content:, id:))
}

pub type ContextManagement {
  ContextManagement(
    /// The context management entry type. Currently only 'compaction' is
    /// supported.
    type_: ContextManagementType,
    /// Token threshold at which compaction should be triggered for this
    /// entry. minimum: 1000
    compact_threshold: Int,
  )
}

pub fn encode_context_management(context_management: ContextManagement) -> Json {
  json.object([
    #("type", encode_context_management_type(context_management.type_)),
    #("compact_threshold", json.int(context_management.compact_threshold)),
  ])
}

pub type ContextManagementType {
  ContextManagementType
}

fn encode_context_management_type(
  context_management_type: ContextManagementType,
) -> Json {
  case context_management_type {
    ContextManagementType -> json.string("compaction")
  }
}

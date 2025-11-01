import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import openai/responses/types/request

pub fn input_list_item_encoder(input_list_item: request.InputListItem) -> Json {
  let input_message_decoder = fn(input_message: request.InputMessage) -> Json {
    let content_item_image_encoder = fn(
      detail: String,
      file_id: Option(String),
      image_url: Option(String),
    ) -> Json {
      json.object([
        #("type", json.string("input_image")),
        #("detail", json.string(detail)),
        case file_id {
          option.None -> {
            let assert option.Some(image_url) = image_url
            #("image_url", json.string(image_url))
          }
          option.Some(file_id) -> #("file_id", json.string(file_id))
        },
      ])
    }

    let content_item_text_encoder = fn(text: String) -> Json {
      json.object([
        #("type", json.string("input_text")),
        #("text", json.string(text)),
      ])
    }

    let content_item_file_encoder = fn(
      file_data: Option(String),
      file_id: Option(String),
      file_url: Option(String),
      filename: Option(String),
    ) -> Json {
      json.object([
        #("type", json.string("input_file")),
        #("file_data", json.nullable(file_data, json.string)),
        #("file_id", json.nullable(file_id, json.string)),
        #("file_url", json.nullable(file_url, json.string)),
        #("filename", json.nullable(filename, json.string)),
      ])
    }

    let request.InputMessage(role:, content:) = input_message
    let process_content = fn() -> Json {
      case content {
        request.ContentInputList(xs) -> {
          json.array(xs, fn(x) {
            case x {
              request.ContentItemFile(
                file_data:,
                file_id:,
                file_url:,
                filename:,
              ) ->
                content_item_file_encoder(
                  file_data,
                  file_id,
                  file_url,
                  filename,
                )
              request.ContentItemImage(detail:, file_id:, image_url:) ->
                content_item_image_encoder(detail, file_id, image_url)
              request.ContentItemText(text:) -> content_item_text_encoder(text)
            }
          })
        }
        request.ContentInputText(text) -> json.string(text)
      }
    }
    json.object([#("role", json.string(role)), #("content", process_content())])
  }

  case input_list_item {
    request.InputListItemMessage(item_message) ->
      input_message_decoder(item_message)
    request.InputListItemReference(id:) ->
      json.object([
        #("id", json.string(id)),
        #("type", json.string("item_reference")),
      ])
  }
}

// TODO support all options by replacing "none"
pub fn tool_choice_encoder(tool_choice: request.ToolChoice) -> Json {
  case tool_choice {
    request.Auto -> json.string("auto")
    request.ComputerUsePreview -> json.string("none")
    request.FileSearch -> json.string("none")
    request.Function(_) -> json.string("none")
    request.None -> json.string("none")
    request.Required -> json.string("required")
    request.WebSearchPreview -> json.string("none")
  }
}

fn user_location_encoder(user_location: Option(request.UserLocation)) -> Json {
  case user_location {
    option.None -> json.null()
    option.Some(request.UserLocation(city, country, region, timezone, type_)) ->
      json.object([
        case type_ {
          option.None -> #("type", json.null())
          option.Some(_) -> #("type", json.string("approximate"))
        },
        case city {
          option.None -> #("city", json.null())
          option.Some(x) -> #("city", json.string(x))
        },
        case country {
          option.None -> #("country", json.null())
          option.Some(x) -> #("country", json.string(x))
        },
        case region {
          option.None -> #("region", json.null())
          option.Some(x) -> #("region", json.string(x))
        },
        case timezone {
          option.None -> #("timezone", json.null())
          option.Some(x) -> #("timezone", json.string(x))
        },
      ])
  }
}

fn search_context_size_encoder(
  search_context_size: Option(request.SearchContextSize),
) -> Json {
  case search_context_size {
    option.None -> json.null()
    option.Some(size) ->
      {
        case size {
          request.SCSHigh -> "high"
          request.SCSLow -> "low"
          request.SCSMedium -> "medium"
        }
      }
      |> json.string()
  }
}

fn web_search_filters_encoder(filters: Option(request.WebSearchFilters)) -> Json {
  case filters {
    option.None -> json.null()
    option.Some(request.WebSearchFilters(allowed_domains)) ->
      json.object([
        #("allowed_domains", allowed_domains_encoder(allowed_domains)),
      ])
  }
}

fn allowed_domains_encoder(allowed_domains: Option(List(String))) -> Json {
  case allowed_domains {
    option.None -> json.null()
    option.Some(xs) -> {
      list.map(xs, fn(x) { json.string(x) })
      |> json.preprocessed_array()
    }
  }
}

pub fn tools_encoder(tools: List(request.Tools)) -> List(Json) {
  list.map(tools, fn(tool: request.Tools) {
    case tool {
      request.WebSearch(filters, search_context_size, user_location) -> {
        web_search_encoder(filters, search_context_size, user_location)
      }
    }
  })
}

fn web_search_encoder(
  filters: Option(request.WebSearchFilters),
  search_context_size: Option(request.SearchContextSize),
  user_location: Option(request.UserLocation),
) -> Json {
  json.object([
    #("type", json.string("web_search")),
    #("filters", web_search_filters_encoder(filters)),
    #("search_context_size", search_context_size_encoder(search_context_size)),
    #("user_location", user_location_encoder(user_location)),
  ])
}

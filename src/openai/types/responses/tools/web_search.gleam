import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers
import openai/types/responses/tools/search_context_size.{type SearchContextSize}
import openai/types/responses/tools/user_location.{type UserLocation}

pub type Status {
  InProgress
  Searching
  Completed
  Failed
}

fn encode_web_search_status(status: Status) -> Json {
  case status {
    InProgress -> "in_progress"
    Searching -> "searching"
    Completed -> "completed"
    Failed -> "failed"
  }
  |> json.string
}

fn decode_web_search_status() -> Decoder(Status) {
  decode.string
  |> decode.map(fn(status) {
    case status {
      "in_progress" -> InProgress
      "searching" -> Searching
      "completed" -> Completed
      "failed" -> Failed
      _ -> panic as status
    }
  })
}

pub type WebSearchCall {
  WebSearchCall(
    /// The unique ID of the web search tool call.
    id: String,
    /// The action performed by the web search tool.
    action: Option(Action),
    /// The status of the web search call.
    status: Status,
    // type: "web_search_call"
  )
}

pub fn encode_web_search_call(web_search_call: WebSearchCall) -> Json {
  [
    #("id", json.string(web_search_call.id)),
    #("type", json.string("web_search_call")),
    #("status", encode_web_search_status(web_search_call.status)),
  ]
  |> helpers.encode_option(
    "action",
    web_search_call.action,
    encode_web_search_action,
  )
  |> json.object
}

pub fn decode_web_search_call() -> Decoder(WebSearchCall) {
  use id <- decode.field("id", decode.string)
  use action <- decode.optional_field(
    "action",
    None,
    decode.optional(decode_web_search_action()),
  )
  use status <- decode.field("status", decode_web_search_status())
  decode.success(WebSearchCall(id:, action:, status:))
}

pub type Action {
  Search(SearchDef)
  OpenPage(OpenPageDef)
  FindInPage(FindInPageDef)
}

fn encode_web_search_action(action: Action) -> Json {
  case action {
    Search(search) -> encode_search_def(search)
    OpenPage(open_page) -> encode_open_page_def(open_page)
    FindInPage(find_in_page) -> encode_find_in_page_def(find_in_page)
  }
}

fn decode_web_search_action() -> Decoder(Action) {
  let search_decoder = fn() {
    use query <- decode.field("query", decode.string)
    use source <- decode.optional_field(
      "sources",
      [],
      decode.list(fn() {
        use url <- decode.field("url", decode.string)
        decode.success(Source(url:))
      }()),
    )
    decode.success(
      Search(SearchDef(queries: Some([query]), source: Some(source))),
    )
  }

  let open_page_decoder = fn() {
    use url <- decode.field("url", decode.string)
    decode.success(OpenPage(OpenPageDef(url: Some(url))))
  }

  let find_in_page_decoder = fn() {
    use pattern <- decode.field("pattern", decode.string)
    use url <- decode.field("url", decode.string)
    decode.success(FindInPage(FindInPageDef(pattern:, url:)))
  }

  use type_ <- decode.field("type", decode.string)
  case type_ {
    "search" -> search_decoder()
    "open_page" -> open_page_decoder()
    "find_in_page" -> find_in_page_decoder()
    _ -> panic as type_
  }
}

pub type SearchDef {
  SearchDef(
    // type: "search"
    /// The search queries issued by the tool.
    queries: Option(List(String)),
    /// The sources returned by the search.
    source: Option(List(Source)),
  )
}

fn encode_search_def(search: SearchDef) -> Json {
  [#("type", json.string("search"))]
  |> helpers.encode_option_list("queries", search.queries, json.string)
  |> helpers.encode_option_list("sources", search.source, encode_source)
  |> json.object
}

pub type Source {
  Source(
    // type: "url"
    url: String,
  )
}

fn encode_source(source: Source) -> Json {
  json.object([
    #("type", json.string("url")),
    #("url", json.string(source.url)),
  ])
}

pub type OpenPageDef {
  OpenPageDef(
    // type: "open_page"
    url: Option(String),
  )
}

fn encode_open_page_def(open_page: OpenPageDef) -> Json {
  [#("type", json.string("open_page"))]
  |> helpers.encode_option("url", open_page.url, json.string)
  |> json.object
}

pub type FindInPageDef {
  FindInPageDef(
    /// The pattern to search for within the page.
    pattern: String,
    // type: "find_in_page"
    /// The URL of the page to search within.
    url: String,
  )
}

fn encode_find_in_page_def(find_in_page: FindInPageDef) -> Json {
  json.object([
    #("type", json.string("find_in_page")),
    #("pattern", json.string(find_in_page.pattern)),
    #("url", json.string(find_in_page.url)),
  ])
}

pub type WebSearch {
  WebSearch(
    // type: "web_search" or "web_search_2025_08_26"

    /// Allowed domains for the search. If not provided, all domains are
    /// allowed. Subdomains of the provided domains are allowed as well.
    /// Example: ["pubmed.ncbi.nlm.nih.gov"]
    filters: Option(Filters),
    /// High level guidance for the amount of context window space to use for
    /// the search. One of low, medium, or high. medium is the default.
    search_context_size: Option(SearchContextSize),
    /// The approximate location of the user.
    user_location: Option(UserLocation),
  )
}

pub fn new_web_search() -> WebSearch {
  WebSearch(filters: None, search_context_size: None, user_location: None)
}

pub fn user_location(
  web_search: WebSearch,
  user_location: UserLocation,
) -> WebSearch {
  WebSearch(..web_search, user_location: Some(user_location))
}

pub fn search_context_size(
  web_search: WebSearch,
  search_context_size: SearchContextSize,
) -> WebSearch {
  WebSearch(..web_search, search_context_size: Some(search_context_size))
}

pub fn encode_web_search(web_search: WebSearch) -> Json {
  [
    #("type", json.string("web_search")),
  ]
  |> helpers.encode_option(
    "user_location",
    web_search.user_location,
    user_location.encode_user_location,
  )
  |> helpers.encode_option("filters", web_search.filters, encode_filters)
  |> helpers.encode_option(
    "search_context_size",
    web_search.search_context_size,
    search_context_size.encode_search_context_size,
  )
  |> json.object
}

pub fn decode_web_search() -> Decoder(WebSearch) {
  use filters <- decode.optional_field(
    "filters",
    None,
    decode.optional(decode_filters()),
  )
  use search_context_size <- decode.field(
    "search_context_size",
    decode.optional(search_context_size.decode_search_context_size()),
  )
  use user_location <- decode.field(
    "user_location",
    decode.optional(user_location.decode_user_location()),
  )
  decode.success(WebSearch(filters:, search_context_size:, user_location:))
}

pub type Filters {
  Filters(allowed_domains: Option(List(String)))
}

pub fn filters(
  web_search: WebSearch,
  allowed_domains: List(String),
) -> WebSearch {
  WebSearch(..web_search, filters: Some(Filters(Some(allowed_domains))))
}

fn encode_filters(filters: Filters) -> Json {
  []
  |> helpers.encode_option_list(
    "allowed_domains",
    filters.allowed_domains,
    json.string,
  )
  |> json.object
}

fn decode_filters() -> Decoder(Filters) {
  use allowed_domains <- decode.optional_field(
    "allowed_domains",
    None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(Filters(allowed_domains))
}

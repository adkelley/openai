import gleam/option.{type Option}
import openai/types as shared

pub type Request {
  Request(
    model: shared.Model,
    input: Input,
    temperature: Option(Float),
    stream: Option(Bool),
    tool_choice: Option(ToolChoice),
    tools: Option(List(Tools)),
  )
}

pub type Input {
  Text(String)
}

pub type Tools {
  WebSearch(
    /// Filters for the search.
    filters: Option(WebSearchFilters),
    /// High level guidance for the amount of context window space to use for the search.
    /// One of low, medium, or high. medium is the default.
    search_context_size: Option(SearchContextSize),
    user_location: Option(UserLocation),
  )
}

pub type WebSearchFilters {
  WebSearchFilters(allowed_domains: Option(List(String)))
}

pub type SearchContextSize {
  SCSLow
  SCSMedium
  SCSHigh
}

pub type UserLocation {
  UserLocation(
    /// Free text input for the city of the user, e.g. San Francisco.
    city: Option(String),
    /// The two-letter ISO country code of the user, e.g. US.
    country: Option(String),
    /// Free text input for the region of the user, e.g. California.
    region: Option(String),
    /// The IANA timezone of the user, e.g. America/Los_Angeles.
    timezone: Option(String),
    /// The type of location approximation. Always approximate.
    type_: Option(String),
  )
}

pub type ToolChoice {
  /// The model will not call any tool and instead generates a message.
  None
  /// The model can pick between generating a message or calling one or more tools.
  Auto
  /// The model must call one or more tools.
  Required
  /// Search the contents of uploaded files when generating a response.
  FileSearch
  /// Include data from the internet in model response generation.
  WebSearchPreview
  /// Create agentic workflows that enable a model to control a computer interface.
  ComputerUsePreview
  /// Enable the model to call custom code that you define, giving it access to additional data and capabilities.
  Function(String)
}

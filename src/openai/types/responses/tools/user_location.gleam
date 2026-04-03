import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/types/helpers

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
    // type: Option("approximate"),
  )
}

pub fn new() -> UserLocation {
  UserLocation(city: None, country: None, region: None, timezone: None)
}

pub fn with_city(user_location: UserLocation, city: String) {
  UserLocation(..user_location, city: Some(city))
}

pub fn with_country(user_location: UserLocation, country: String) {
  UserLocation(..user_location, country: Some(country))
}

pub fn with_region(user_location: UserLocation, region: String) {
  UserLocation(..user_location, region: Some(region))
}

pub fn with_timezone(user_location: UserLocation, timezone: String) {
  UserLocation(..user_location, timezone: Some(timezone))
}

pub fn encode_user_location(user_location: UserLocation) -> Json {
  helpers.encode_option([], "city", user_location.city, json.string)
  |> helpers.encode_option("country", user_location.country, json.string)
  |> helpers.encode_option("region", user_location.region, json.string)
  |> helpers.encode_option("timezone", user_location.timezone, json.string)
  |> list.prepend(#("type", json.string("approximate")))
  |> json.object
}

pub fn decode_user_location() -> Decoder(UserLocation) {
  use city <- decode.field("city", decode.optional(decode.string))
  use country <- decode.field("country", decode.optional(decode.string))
  use region <- decode.field("region", decode.optional(decode.string))
  use timezone <- decode.field("timezone", decode.optional(decode.string))
  decode.success(UserLocation(city:, country:, region:, timezone:))
}

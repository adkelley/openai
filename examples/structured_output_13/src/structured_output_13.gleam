import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/message
import openai/types/responses/response

pub type Category {
  Billing
  Bug
  FeatureRequest
  Account
}

pub type Severity {
  Low
  Medium
  High
}

pub type TicketSummary {
  TicketSummary(
    customer_name: String,
    company_name: String,
    issue_summary: String,
    category: Category,
    severity: Severity,
    requires_follow_up: Bool,
    suggested_actions: List(String),
  )
}

pub fn main() -> Result(TicketSummary, OpenAIError) {
  let assert Ok(client) = client.new()

  let ticket_text =
    "Hi, this is Alice from Acme Co. I was charged twice for our March invoice after updating our payment method. Please refund the duplicate charge and email me when it has been resolved."
  io.println("\nInput ticket: " <> ticket_text)

  let schema = ticket_summary_schema()
  let text_config =
    response.new_text_param()
    |> response.text_format(response.ResponseFormatJSONSchemaConfig(
      name: "ticket_summary",
      schema: schema,
    ))

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_input(response.Text(ticket_text))
    |> responses.with_instructions(
      "Extract the support ticket into valid JSON only. Follow the schema exactly and do not add extra fields.",
    )
    |> responses.with_text(text_config)

  let assert Ok(api_response) = responses.create(client, request)
  let assert Some(output_message) = find_output_message(api_response.output)
  let assert [message.OutputTextItem(message.OutputText(text:, ..)), ..] =
    output_message.content
  let assert Ok(ticket) = json.parse(text, decode_ticket_summary())

  io.println("\nStructured extraction:")
  io.println("Customer: " <> ticket.customer_name)
  io.println("Company: " <> ticket.company_name)
  io.println("Category: " <> category_to_string(ticket.category))
  io.println("Severity: " <> severity_to_string(ticket.severity))
  io.println(
    "Requires follow-up: " <> bool_to_string(ticket.requires_follow_up),
  )
  io.println(
    "Suggested actions: "
    <> int_to_string(list.length(ticket.suggested_actions)),
  )

  Ok(ticket)
}

fn ticket_summary_schema() -> Json {
  json.object([
    #("type", json.string("object")),
    #(
      "properties",
      json.object([
        #(
          "customer_name",
          json.object([
            #("type", json.string("string")),
            #("description", json.string("Name of the customer or reporter")),
          ]),
        ),
        #(
          "company_name",
          json.object([
            #("type", json.string("string")),
            #("description", json.string("Name of the company reporting")),
          ]),
        ),
        #(
          "issue_summary",
          json.object([
            #("type", json.string("string")),
            #("description", json.string("Short summary of the primary issue")),
          ]),
        ),
        #(
          "category",
          json.object([
            #("type", json.string("string")),
            #(
              "enum",
              json.array(
                ["billing", "bug", "feature_request", "account"],
                json.string,
              ),
            ),
          ]),
        ),
        #(
          "severity",
          json.object([
            #("type", json.string("string")),
            #("enum", json.array(["low", "medium", "high"], json.string)),
          ]),
        ),
        #(
          "requires_follow_up",
          json.object([
            #("type", json.string("boolean")),
          ]),
        ),
        #(
          "suggested_actions",
          json.object([
            #("type", json.string("array")),
            #(
              "items",
              json.object([
                #("type", json.string("string")),
              ]),
            ),
          ]),
        ),
      ]),
    ),
    #(
      "required",
      json.array(
        [
          "customer_name",
          "company_name",
          "issue_summary",
          "category",
          "severity",
          "requires_follow_up",
          "suggested_actions",
        ],
        json.string,
      ),
    ),
    #("additionalProperties", json.bool(False)),
  ])
}

fn decode_ticket_summary() -> decode.Decoder(TicketSummary) {
  use customer_name <- decode.field("customer_name", decode.string)
  use company_name <- decode.field("company_name", decode.string)
  use issue_summary <- decode.field("issue_summary", decode.string)
  use category <- decode.field("category", decode_category())
  use severity <- decode.field("severity", decode_severity())
  use requires_follow_up <- decode.field("requires_follow_up", decode.bool)
  use suggested_actions <- decode.field(
    "suggested_actions",
    decode.list(decode.string),
  )
  decode.success(TicketSummary(
    customer_name:,
    company_name:,
    issue_summary:,
    category:,
    severity:,
    requires_follow_up:,
    suggested_actions:,
  ))
}

fn decode_category() -> decode.Decoder(Category) {
  decode.string
  |> decode.map(fn(value) {
    case value {
      "billing" -> Billing
      "bug" -> Bug
      "feature_request" -> FeatureRequest
      "account" -> Account
      _ -> panic as value
    }
  })
}

fn decode_severity() -> decode.Decoder(Severity) {
  decode.string
  |> decode.map(fn(value) {
    case value {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      _ -> panic as value
    }
  })
}

fn find_output_message(
  output: List(response.InputOutput),
) -> Option(message.ResponseOutputMessage) {
  case output {
    [response.ResponseOutputMessageItem(response_output_message), ..] ->
      Some(response_output_message)
    [_, ..rest] -> find_output_message(rest)
    [] -> None
  }
}

fn category_to_string(category: Category) -> String {
  case category {
    Billing -> "billing"
    Bug -> "bug"
    FeatureRequest -> "feature_request"
    Account -> "account"
  }
}

fn severity_to_string(severity: Severity) -> String {
  case severity {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

fn bool_to_string(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}

fn int_to_string(value: Int) -> String {
  int.to_string(value)
}

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}

pub type Status {
  InProgress
  Completed
  Incomplete
}

pub type ComputerCallDef {
  ComputerCallDef(
    /// The unique ID of the computer call.
    id: String,
    /// The action to perform on the computer.
    action: Action,
    /// Pending safety checks for the computer action.
    pending_safety_checks: PendingSafetyChecks,
    /// The status of the item. One of in_progress, completed, or incomplete.
    status: Status,
    // type: "computer_call"
  )
}

// TODO Write encoders and decoders.

// TODO: Remaining actions
pub type Action {
  ClickAction(Click)
}

pub type Click {
  Click(
    /// Indicates which mouse button was pressed during the click.
    button: Button,
    // type: "click"
    /// The x-coordinate where the click occurred.
    x: Float,
    /// The y-coordinate where the click occurred.
    y: Float,
  )
}

pub type Button {
  Left
  Right
  Wheel
  Back
  Forward
}

pub type PendingSafetyChecks {
  PendingSafetyChecks(id: String, code: Option(String))
}

pub type Computer {
  // type: computer
  Computer
}

pub fn encode_computer() -> Json {
  json.object([#("type", json.string("computer"))])
}

pub fn decode_computer() -> Decoder(Computer) {
  use _ <- decode.field("type", decode.string)
  decode.success(Computer)
}

pub type ComputerCallOutputDef {
  ComputerCallOutputDef(
    /// The ID of the computer tool call that produced the output.
    call_id: String,
    /// The screenshot output from the computer tool call.
    output: ComputerScreenShot,
    // type: "computer_call_output"
    /// The unique ID of the computer tool call output.
    id: Option(String),
    /// Safety checks acknowledged for this computer tool call output.
    acknowledged_safety_checks: AcknowledgedSafetyChecks,
    /// The status of the item. One of in_progress, completed, or incomplete.
    status: Status,
  )
}

// TODO write encoders and decoders.

pub type ComputerScreenShot {
  ComputerScreenShot(
    // type: "computer_screenshot"
    /// The ID of the file containing the screenshot.
    file_id: Option(String),
    /// The URL of the screenshot image.
    image_url: Option(String),
  )
}

pub type AcknowledgedSafetyChecks {
  AcknowledgedSafetyChecks(
    /// The ID of the acknowledged safety check.
    id: String,
    /// The machine-readable code for the acknowledged safety check.
    code: Option(String),
    /// The human-readable message for the acknowledged safety check.
    message: Option(String),
  )
}

pub type ComputerUsePreview {
  ComputerUsePreview(
    /// The height of the computer display.
    display_height: Int,
    /// The width of the computer display.
    display_width: Int,
    /// The type of computer environment to control
    environment: Environment,
    // type: "computer_use_preview"
  )
}

pub fn encode_computer_use_preview(preview: ComputerUsePreview) -> Json {
  json.object([
    #("type", json.string("computer_use_preview")),
    #("display_height", json.int(preview.display_height)),
    #("display_width", json.int(preview.display_width)),
    #("environment", encode_environment(preview.environment)),
  ])
}

pub fn decode_computer_use_preview() -> Decoder(ComputerUsePreview) {
  use display_height <- decode.field("display_height", decode.int)
  use display_width <- decode.field("display_width", decode.int)
  use environment <- decode.field("environment", decode_environment())
  decode.success(ComputerUsePreview(
    display_height:,
    display_width:,
    environment:,
  ))
}

pub type Environment {
  Windows
  Mac
  Linux
  Ubuntu
  Browser
}

fn encode_environment(environment: Environment) -> Json {
  case environment {
    Windows -> json.string("windows")
    Mac -> json.string("mac")
    Linux -> json.string("linux")
    Ubuntu -> json.string("ubuntu")
    Browser -> json.string("browser")
  }
}

pub fn decode_environment() -> Decoder(Environment) {
  decode.string
  |> decode.map(fn(environment) {
    case environment {
      "windows" -> Windows
      "mac" -> Mac
      "linux" -> Linux
      "ubuntu" -> Ubuntu
      "browser" -> Browser
      _ -> panic as environment
    }
  })
}

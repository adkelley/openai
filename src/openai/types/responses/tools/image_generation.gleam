import gleam/json.{type Json}
import gleam/option.{type Option}
import openai/types/helpers

pub type Status {
  InProgress
  Completed
  Generating
  Failed
}

pub type ImageGenEnum(narrowed) {
  Generate
  Edit
  Auto
  Transparent
  Opaque
  Low
  Medium
  High
}

pub type ImageGeneration {
  ImageGeneration(
    // type: "image_generation"
    /// Whether to generate a new image or edit an existing image. Default:
    /// auto.
    action: Option(Action),
    /// Background type for the generated image.
    background: Option(Background),
    /// Control how much effort the model will exert to match the style and
    /// features, especially facial features, of input images. This parameter
    /// is only supported for gpt-image-1 and gpt-image-1.5 and later models,
    /// unsupported for gpt-image-1-mini. Supports high and low. Defaults to
    /// low.
    input_fidelity: Option(InputFidelity),
    /// Optional mask for inpainting. Contains image_url (string, optional)
    /// and file_id (string, optional).
    input_image_mask: Option(InputImageMask),
    /// The image generation model to use. Default: gpt-image-1.
    model: Option(Model),
    /// Moderation level for the generated image. Default: auto.
    moderation: Option(Moderation),
    /// Compression level for the output image. Default: 100.
    compression: Option(Int),
    /// The output format of the generated image. One of png, webp, or jpeg.
    /// Default: png.
    output_format: Option(OutputFormat),
    /// Number of partial images to generate in streaming mode, from 0 (
    /// default value) to 3.
    partial_images: Option(Int),
    /// The quality of the generated image. One of low, medium, high, or auto.
    /// Default: auto.
    quality: Option(Quality),
    /// The size of the generated image. One of 1024x1024, 1024x1536,
    /// 1536x1024, or auto. Default: auto.
    size: Option(Size),
  )
}

pub fn encode_image_gen(image_generation: ImageGeneration) -> Json {
  [
    #("type", json.string("image_generation")),
  ]
  |> helpers.encode_option(
    "action",
    image_generation.action,
    encode_image_gen_action,
  )
  |> helpers.encode_option(
    "background",
    image_generation.background,
    encode_image_gen_background,
  )
  |> helpers.encode_option(
    "input_fidelity",
    image_generation.input_fidelity,
    encode_image_gen_input_fidelity,
  )
  |> helpers.encode_option(
    "input_image_mask",
    image_generation.input_image_mask,
    encode_input_image_mask,
  )
  |> helpers.encode_option(
    "model",
    image_generation.model,
    encode_image_gen_model,
  )
  |> helpers.encode_option(
    "moderation",
    image_generation.moderation,
    encode_image_gen_moderation,
  )
  |> helpers.encode_option(
    "compression",
    image_generation.compression,
    json.int,
  )
  |> helpers.encode_option(
    "output_format",
    image_generation.output_format,
    encode_image_gen_output_format,
  )
  |> helpers.encode_option(
    "partial_images",
    image_generation.partial_images,
    json.int,
  )
  |> helpers.encode_option(
    "quality",
    image_generation.quality,
    encode_image_gen_quality,
  )
  |> helpers.encode_option("size", image_generation.size, encode_image_gen_size)
  |> json.object
}

pub type Action

pub fn action(image_gen_enum: ImageGenEnum(any)) -> ImageGenEnum(Action) {
  case image_gen_enum {
    Generate -> Generate
    Edit -> Edit
    Auto -> Auto
    _ -> Auto
  }
}

fn encode_image_gen_action(_action: Action) -> Json {
  json.string("auto")
}

pub type Background

pub fn background(image_gen_enum: ImageGenEnum(any)) -> ImageGenEnum(Background) {
  case image_gen_enum {
    Transparent -> Transparent
    Opaque -> Opaque
    Auto -> Auto
    _ -> Auto
  }
}

fn encode_image_gen_background(_background: Background) -> Json {
  json.string("auto")
}

pub type InputFidelity

pub fn input_fidelity(
  image_gen_enum: ImageGenEnum(any),
) -> ImageGenEnum(InputFidelity) {
  case image_gen_enum {
    High -> High
    Low -> Low
    _ -> Low
  }
}

fn encode_image_gen_input_fidelity(_input_fidelity: InputFidelity) -> Json {
  json.string("low")
}

pub type InputImageMask {
  InputImageMask(file_id: Option(String), image_url: Option(String))
}

fn encode_input_image_mask(input_image_mask: InputImageMask) -> Json {
  helpers.encode_option([], "file_id", input_image_mask.file_id, json.string)
  |> helpers.encode_option("image_url", input_image_mask.image_url, json.string)
  |> json.object
}

pub type Model {
  GPTImage1
  GPTImage1Mini
  GPTImage15
}

fn encode_image_gen_model(model: Model) -> Json {
  case model {
    GPTImage1 -> json.string("gpt-image-1")
    GPTImage1Mini -> json.string("gpt-image-1-mini")
    GPTImage15 -> json.string("gpt-image-1.5")
  }
}

pub type Moderation

pub fn moderation(image_gen_enum: ImageGenEnum(any)) -> ImageGenEnum(Moderation) {
  case image_gen_enum {
    Low -> Low
    Auto -> Auto
    _ -> Auto
  }
}

fn encode_image_gen_moderation(_moderation: Moderation) -> Json {
  json.string("auto")
}

pub type OutputFormat {
  Png
  Webp
  Jpeg
}

fn encode_image_gen_output_format(output_format: OutputFormat) -> Json {
  case output_format {
    Png -> json.string("png")
    Webp -> json.string("webp")
    Jpeg -> json.string("jpeg")
  }
}

pub type Quality

pub fn quality(image_gen_enum: ImageGenEnum(any)) -> ImageGenEnum(Quality) {
  case image_gen_enum {
    Low -> Low
    Medium -> Medium
    High -> High
    Auto -> Auto
    _ -> Auto
  }
}

fn encode_image_gen_quality(_quality: Quality) -> Json {
  json.string("auto")
}

pub type Size {
  Size1024x1024
  Size1024x1536
  Size1536x1024
  SizeAuto
}

fn encode_image_gen_size(size: Size) -> Json {
  case size {
    Size1024x1024 -> json.string("1024x1024")
    Size1024x1536 -> json.string("1024x1536")
    Size1536x1024 -> json.string("1536x1024")
    SizeAuto -> json.string("auto")
  }
}

pub type ImageGenerationCall {
  ImageGenerationCall(
    /// The unique ID of the image generation call.
    id: String,
    /// The generated image result.
    result: String,
    /// The status of the image generation call.
    status: Status,
    // type "image_generation_call"
  )
}

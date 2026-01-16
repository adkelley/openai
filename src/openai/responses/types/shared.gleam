pub type OutputReasoning {
  OutputReasoning(
    /// The unique identifier of the reasoning content.
    id: String,
    /// Reasoning summary content.
    summary: List(OutputReasoningSummary),
    /// Reasoning text content.
    content: List(OutputReasoningContent),
  )
}

/// Reasoning text content.
pub type OutputReasoningSummary {
  OutputReasoningSummary(text: String)
}

pub type OutputReasoningContent {
  OutputReasoningContent(text: String)
}

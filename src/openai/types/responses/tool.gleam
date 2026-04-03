import gleam/json.{type Json}
import openai/types/responses/tools/apply_patch
import openai/types/responses/tools/code_interpreter
import openai/types/responses/tools/computer
import openai/types/responses/tools/custom
import openai/types/responses/tools/file_search
import openai/types/responses/tools/function
import openai/types/responses/tools/image_generation
import openai/types/responses/tools/mcp
import openai/types/responses/tools/shell
import openai/types/responses/tools/web_search
import openai/types/responses/tools/web_search_preview

pub type Tool {
  /// Defines a function in your own code the model can choose to call. Learn
  /// more about [functioncalling](https://platform.openai.com/docs/guides/
  /// tools).
  FunctionTool(function.Function)
  /// A tool that searches for relevant content from uploaded files. Learn
  /// more about the [file search tool](https://platform.openai.com/docs/
  /// guides/tools-file-search).
  FileSearchTool(file_search.FileSearch)
  /// A tool that controls a virtual computer. Learn more about the [computer
  /// use tool](https://platform.openai.com/docs/guides/tools-computer-use).
  ComputerTool(computer.Computer)
  /// A tool that controls a virtual computer
  ComputerUsePreviewTool(computer.ComputerUsePreview)
  /// Give the model access to additional tools via remote Model Context
  /// Protocol (MCP) servers.
  McpTool(mcp.Mcp)
  /// A tool that runs Python code to help generate a response to a prompt.
  CodeInterpreterTool(code_interpreter.CodeInterpreter)
  /// A tool that generates images using a model like `gpt-image-1`.
  ImageGenerationTool(image_generation.ImageGeneration)
  /// A tool that allows the model to execute shell commands in a local
  /// environment.
  LocalShellTool(shell.LocalShell)
  // type: "local_shell"
  /// A tool that allows the model to execute shell commands.
  ShellTool(shell.Shell)
  /// A custom tool that processes input using a specified format. Learn more
  CustomTool(custom.Custom)
  /// Search the Internet for sources related to the prompt.
  WebSearchTool(web_search.WebSearch)
  /// This tool searches the web for relevant results to use in a response.
  WebSearchPreviewTool(web_search_preview.WebSearchPreview)
  /// Allows the assistant to create, delete, or update files using unified
  /// diffs.
  ApplyPatchTool
}

pub fn encode_tool(tool: Tool) -> Json {
  case tool {
    FunctionTool(function) -> function.encode_function(function)
    FileSearchTool(file_search) -> file_search.encode_file_search(file_search)
    ComputerTool(_) -> computer.encode_computer()
    ComputerUsePreviewTool(preview) ->
      computer.encode_computer_use_preview(preview)
    WebSearchTool(web_search) -> web_search.encode_web_search(web_search)
    WebSearchPreviewTool(preview) ->
      web_search_preview.encode_web_search_preview(preview)
    McpTool(mcp) -> mcp.encode_mcp(mcp)
    CodeInterpreterTool(interpreter) ->
      code_interpreter.encode_code_interpreter(interpreter)
    ImageGenerationTool(image_generation) ->
      image_generation.encode_image_gen(image_generation)
    LocalShellTool(_) -> shell.encode_local_shell()
    ShellTool(shell) -> shell.encode_shell(shell)
    CustomTool(custom) -> custom.encode_custom(custom)
    ApplyPatchTool -> apply_patch.encode_apply_patch()
  }
}

defmodule LiveAiElements.Ansi do
  @moduledoc """
  Where a program's output becomes HTML.

  AI Elements draws terminal output with `ansi-to-react`, which turns the escape
  codes a program writes for colour — `\\e[31m` and its forty relatives — into
  spans a browser can paint. Without it the codes are printed as the mojibake
  they are.

  Elixir has that already, so this module is a seam and not an implementation,
  for the same reason `LiveAiElements.Markdown` is one: a component library that
  drags a renderer behind it cannot be adopted by somebody who already has one.

  ## Choosing a renderer

  Adding `ansi_to_html` is enough — it is the default when it is there. To use
  something else:

      config :live_ai_elements, ansi: MyApp.Ansi

  It is an optional dependency, so an application whose programs write no colour
  pulls in nothing. With no renderer the output is rendered as text, which is
  what a terminal without colour shows and is at least not a crash.

  ## Writing one

  A renderer is a `Phoenix.Component` with an `ansi/1` function taking two
  attributes:

    * `:content` — the output, escape codes and all
    * `:class`

  It is called as a function rather than from a HEEx tag, because which module
  it is, is a runtime decision — so declare both attributes and read them out of
  the assigns you were handed rather than relying on a default.
  """

  use Phoenix.Component

  @callback ansi(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  # Compiled only when the dependency is there, for the reason
  # `LiveAiElements.Markdown.Streamdown` gives: a HEEx tag is what applies a
  # component's `attr` defaults, and the seam cannot write one for a module it
  # does not know at compile time.
  if Code.ensure_loaded?(AnsiToHTML) do
    defmodule AnsiToHtml do
      @moduledoc """
      Renders through `ansi_to_html`. Compiled only when it is a dependency.
      """
      @behaviour LiveAiElements.Ansi

      use Phoenix.Component

      @impl true
      def ansi(assigns) do
        assigns = assign(assigns, :html, AnsiToHTML.generate_html(assigns.content))

        ~H"""
        <span class={@class}>{@html}</span>
        """
      end
    end
  end

  @doc """
  Renders terminal output with whichever renderer the application has.

  ## Attributes

    * `:content` — the output, escape codes and all
    * `:class`
  """
  attr(:content, :string, default: "")
  attr(:class, :any, default: nil)

  def ansi(assigns) do
    case renderer() do
      nil -> plain(assigns)
      module -> module.ansi(assigns)
    end
  end

  @doc """
  The renderer in use, or `nil`.

  Configuration first, then the built-in `ansi_to_html` adapter if that
  dependency is present. Returns `nil` rather than raising when a configured
  module is not loaded, because a missing optional dependency should degrade a
  transcript, not stop an application from booting.
  """
  @spec renderer() :: module() | nil
  def renderer do
    case Application.get_env(:live_ai_elements, :ansi, __MODULE__.AnsiToHtml) do
      nil -> nil
      module -> if Code.ensure_loaded?(module), do: module
    end
  end

  # No renderer. The output is still the output, and a terminal that shows it
  # without colour is a terminal without colour.
  defp plain(assigns) do
    ~H"""
    <span class={@class}>{@content}</span>
    """
  end
end

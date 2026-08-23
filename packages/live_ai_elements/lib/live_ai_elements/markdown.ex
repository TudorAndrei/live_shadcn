defmodule LiveAiElements.Markdown do
  @moduledoc """
  Where a model's prose becomes HTML.

  AI Elements renders assistant text with Streamdown, a markdown renderer built
  for output that is still arriving: it closes the syntax a half-finished
  message left open, so a lone `**` does not turn the rest of the conversation
  bold while the next token is on its way.

  Elixir has that already. `phoenix_streamdown` does the same job for LiveView,
  server-side, and re-renders only the block that is still changing rather than
  the whole message. So this module is a seam, not an implementation.

  ## Choosing a renderer

  Adding `phoenix_streamdown` is enough — it is the default when it is there.
  To use something else:

      config :live_ai_elements, markdown: MyApp.Markdown

  It is an optional dependency, so an application that renders its own markdown,
  or renders none, pulls in nothing. With no renderer at all the text is
  rendered as text, which is wrong for a model that writes markdown and is at
  least not a crash.

  ## Writing one

  A renderer is a `Phoenix.Component` with a `markdown/1` function taking three
  attributes:

    * `:content` — the markdown source
    * `:streaming` — whether more of it is still arriving. A renderer built for
      streaming uses it to decide what to leave alone.
    * `:class`

  Those three are what `phoenix_streamdown` already takes, because they are what
  the job needs, and copying its shape saves every other renderer from inventing
  a different one.

  A renderer is called as a function rather than from a HEEx tag, because which
  module it is, is a runtime decision. Phoenix fills an `attr` default in at the
  call site, so a function called this way never gets one: declare the three
  attributes, and read them out of the assigns you were handed rather than
  relying on a default.

  ## Why this is not hard-wired

  A component library that drags a markdown renderer behind it cannot be adopted
  by somebody who already has one, and everybody who renders LLM output already
  has one. That is the argument `live_base` makes for having exactly one
  dependency, one layer up.
  """

  use Phoenix.Component

  @callback markdown(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  # Compiled only when the dependency is there. It exists so that adding
  # `phoenix_streamdown` is the whole setup: a HEEx tag is what applies a
  # component's `attr` defaults, and the seam cannot write one for a module it
  # does not know at compile time.
  if Code.ensure_loaded?(PhoenixStreamdown) do
    defmodule Streamdown do
      @moduledoc """
      Renders through `phoenix_streamdown`. Compiled only when it is a dependency.

      ## Colour in a code block

      `phoenix_streamdown` always asks MDEx for syntax highlighting, and MDEx
      raises unless a highlighter is installed. It catches that and renders the
      block as escaped text, so a conversation that should show `**bold**` shows
      `**bold**` and nothing says why. Every message, not just the code ones.

      So this adapter asks for no highlighting when no highlighter is
      configured. Markdown renders; code is not coloured. To colour it, add the
      highlighter and tell MDEx to use it **before** dependencies compile:

          # mix.exs
          {:lumis, "~> 0.7"}

          # config/config.exs
          config :mdex_native, syntax_highlighter: :lumis

      `lumis` is Tree-sitter and Neovim themes, and it is what shadcn's own
      `code-block` uses `shiki` for.
      """
      @behaviour LiveAiElements.Markdown

      use Phoenix.Component

      @impl true
      def markdown(assigns) do
        assigns = assign(assigns, :mdex_opts, mdex_opts())

        ~H"""
        <PhoenixStreamdown.markdown
          content={@content}
          streaming={@streaming}
          class={@class}
          mdex_opts={@mdex_opts}
        />
        """
      end

      defp mdex_opts do
        if Application.get_env(:mdex_native, :syntax_highlighter),
          do: [],
          else: [syntax_highlight: nil]
      end
    end
  end

  @doc """
  Renders markdown with whichever renderer the application has.

  ## Attributes

    * `:content` — the markdown source
    * `:streaming` — whether more of it is still arriving
    * `:class`
  """
  attr(:content, :string, default: "")
  attr(:streaming, :boolean, default: false)
  attr(:class, :any, default: nil)

  def markdown(assigns) do
    case renderer() do
      nil -> plain(assigns)
      module -> module.markdown(assigns)
    end
  end

  @doc """
  The renderer in use, or `nil`.

  Configuration first, then the built-in `phoenix_streamdown` adapter if that
  dependency is present. Returns `nil` rather than raising when a configured
  module is not loaded, because a missing optional dependency should degrade a
  conversation, not stop an application from booting.
  """
  @spec renderer() :: module() | nil
  def renderer do
    case Application.get_env(:live_ai_elements, :markdown, __MODULE__.Streamdown) do
      nil -> nil
      module -> if Code.ensure_loaded?(module), do: module
    end
  end

  # No renderer. The text is still the message, and showing it unformatted is
  # better than showing nothing or raising inside a render.
  defp plain(assigns) do
    ~H"""
    <div class={@class}>{@content}</div>
    """
  end
end

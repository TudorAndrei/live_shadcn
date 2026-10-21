defmodule LiveShadcn.UI.CodeBlock do
  @moduledoc """
  Reviewed code block parts from the pinned shadcn source.

  The marked facts follow upstream. The component body implements the LiveView API.
  """
  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/codeBlockLineVariants/base" =>
      "cn-code-block-line relative block min-h-lh after:absolute after:top-0 after:select-none in-data-numbered:col-span-2 in-data-numbered:grid in-data-numbered:grid-cols-subgrid in-data-numbered:[counter-increment:line] in-data-numbered:before:content-[counter(line)] in-data-numbered:before:select-none in-data-numbered:supports-[content:counter(line)_/_'']:before:content-[counter(line)_/_'']",
    "cva/codeBlockLineVariants/default/variant" => "default",
    "cva/codeBlockLineVariants/variant/variant/added" => "cn-code-block-line-variant-added",
    "cva/codeBlockLineVariants/variant/variant/default" => "cn-code-block-line-variant-default",
    "cva/codeBlockLineVariants/variant/variant/highlighted" =>
      "cn-code-block-line-variant-highlighted",
    "cva/codeBlockLineVariants/variant/variant/removed" => "cn-code-block-line-variant-removed",
    "cva/codeBlockVariants/base" =>
      "cn-code-block group/code-block relative flex w-full min-w-0 flex-col overflow-hidden",
    "cva/codeBlockVariants/default/variant" => "default",
    "cva/codeBlockVariants/variant/variant/default" => "cn-code-block-variant-default",
    "cva/codeBlockVariants/variant/variant/destructive" => "cn-code-block-variant-destructive",
    "jsx/CodeBlockActions/class/0" =>
      "cn-code-block-actions ms-auto flex shrink-0 items-center [[data-slot=code-block]>&]:absolute [[data-slot=code-block]>&]:z-10 [[data-slot=code-block]>&]:opacity-0 [[data-slot=code-block]>&]:transition-opacity [[data-slot=code-block]>&]:group-focus-within/code-block:opacity-100 [[data-slot=code-block]>&]:group-hover/code-block:opacity-100 [[data-slot=code-block]>&]:pointer-coarse:opacity-100",
    "jsx/CodeBlockContent/class/0" =>
      "cn-code-block-content min-h-0 min-w-0 scroll-fade-x scrollbar-thin overflow-auto text-start font-mono outline-none data-wrap:scroll-fade-y data-wrap:wrap-break-word data-wrap:whitespace-pre-wrap",
    "jsx/CodeBlockContent/class/1" =>
      "cn-code-block-code grid min-h-lh min-w-max content-start in-data-numbered:grid-cols-[auto_1fr] in-data-wrap:min-w-0",
    "jsx/CodeBlockCopyButton/class/0" => "cn-code-block-copy-button",
    "jsx/CodeBlockCopyButton/class/1" => "sr-only",
    "jsx/CodeBlockFooter/class/0" => "cn-code-block-footer flex min-w-0 shrink-0 items-center",
    "jsx/CodeBlockHeader/class/0" =>
      "cn-code-block-header flex min-w-0 shrink-0 items-center *:has-[>[data-slot=code-block-title]]:min-w-0",
    "jsx/CodeBlockLine/class/0" => "min-w-0",
    "jsx/CodeBlockTitle/class/0" =>
      "cn-code-block-title min-w-0 truncate [&_svg]:pointer-events-none [&_svg]:inline-block [&_svg]:align-middle"
  }
  # live-shadcn: upstream facts end

  defp fact(key), do: Map.fetch!(@upstream_facts, key)
  defp classes(values), do: LiveShadcn.Cn.merge(values)

  @doc "Renders the code block header part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_header(assigns) do
    ~H"""
    <div data-slot="code-block-header" class={classes([fact("jsx/CodeBlockHeader/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders the code block title part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_title(assigns) do
    ~H"""
    <div data-slot="code-block-title" class={classes([fact("jsx/CodeBlockTitle/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders the code block actions part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_actions(assigns) do
    ~H"""
    <div data-slot="code-block-actions" class={classes([fact("jsx/CodeBlockActions/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders the code block footer part."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_footer(assigns) do
    ~H"""
    <div data-slot="code-block-footer" class={classes([fact("jsx/CodeBlockFooter/class/0"), @class])}  {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders a code block root."
  attr(:variant, :string,
    default: @upstream_facts["cva/codeBlockVariants/default/variant"],
    values: ["default", "destructive"]
  )

  attr(:size, :string, default: "default", values: ["default", "sm"])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block(assigns) do
    ~H"""
    <div data-slot="code-block" data-variant={@variant} data-size={@size} class={classes([fact("cva/codeBlockVariants/base"), fact("cva/codeBlockVariants/variant/variant/" <> @variant), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Renders code with optional wrapping and line numbers. The text remains escaped."
  attr(:code, :string, default: nil)
  attr(:wrap, :boolean, default: false)
  attr(:line_numbers, :boolean, default: false)
  attr(:start_line, :integer, default: 1)
  attr(:style, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_content(assigns) do
    lines =
      if assigns.code == nil,
        do: [],
        else: assigns.code |> String.replace(~r/\n$/, "") |> String.split("\n")

    assigns = assign(assigns, :lines, lines)

    ~H"""
    <pre phx-no-format data-slot="code-block-content" data-wrap={if @wrap, do: ""} data-numbered={if @line_numbers, do: ""} dir="ltr" tabindex="0" style={"counter-reset:line #{@start_line - 1};#{@style}"} class={classes([fact("jsx/CodeBlockContent/class/0"), @class])} {@rest}><code data-slot="code-block-code" class={fact("jsx/CodeBlockContent/class/1")}><%= cond do %><% @code != nil and @line_numbers -> %><.code_block_line :for={line <- @lines} value={line} /><% @code != nil -> %>{@code}<% true -> %>{render_slot(@inner_block)}<% end %></code></pre>
    """
  end

  @doc "Renders a code line. Empty lines contain a newline for text selection."
  attr(:variant, :string,
    default: @upstream_facts["cva/codeBlockLineVariants/default/variant"],
    values: ["default", "added", "removed", "highlighted"]
  )

  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def code_block_line(assigns) do
    ~H"""
    <span phx-no-format data-slot="code-block-line" data-variant={@variant} class={classes([fact("cva/codeBlockLineVariants/base"), fact("cva/codeBlockLineVariants/variant/variant/" <> @variant), @class])} {@rest}><span data-slot="code-block-line-content" class={fact("jsx/CodeBlockLine/class/0")}><%= if @value != nil do %>{if @value == "", do: "\n", else: @value}<% else %>{if @inner_block == [], do: "\n", else: render_slot(@inner_block)}<% end %></span></span>
    """
  end

  @doc "Copies the supplied text and announces success for two seconds."
  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:variant, :string, default: "ghost")
  attr(:size, :string, default: "icon-xs")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["disabled", "type"])

  def code_block_copy_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button id={@id} type="button" data-slot="code-block-copy-button" variant={@variant} size={@size} class={classes([fact("jsx/CodeBlockCopyButton/class/0"), @class])} aria-label="Copy" data-lb-clipboard={@value} data-lb-copy-label data-lb-copy-status={@id <> "-status"} phx-hook={LiveBase.Clipboard.hook()} phx-mounted={LiveBase.Clipboard.owned_attributes() |> Phoenix.LiveView.JS.ignore_attributes(["aria-label", "data-copied"], [])} {@rest}>
      <LiveShadcn.Icon.icon name="copy" data-lb-state="idle" />
      <LiveShadcn.Icon.icon name="check" data-lb-state="copied" hidden />
    </LiveShadcn.UI.Button.button>
    <span id={@id <> "-status"} aria-live="polite" phx-update="ignore" class={fact("jsx/CodeBlockCopyButton/class/1")}></span>
    """
  end
end

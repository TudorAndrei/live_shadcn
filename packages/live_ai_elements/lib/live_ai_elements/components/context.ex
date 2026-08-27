defmodule LiveAiElements.Components.Context do
  @moduledoc """
  Context. Built on `shadcn/hover-card`.

  Upstream exports 3 more parts, each a thin
  wrapper around a part of `<.hover_card>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ContextCacheUsage/class/0" => "flex items-center justify-between text-xs",
    "jsx/ContextCacheUsage/class/1" => "text-muted-foreground",
    "jsx/ContextContentBody/class/0" => "w-full p-3",
    "jsx/ContextContentFooter/class/0" =>
      "flex w-full items-center justify-between gap-3 bg-secondary p-3 text-xs",
    "jsx/ContextContentHeader/class/0" => "w-full space-y-2 p-3",
    "jsx/ContextContentHeader/class/1" => "flex items-center justify-between gap-3 text-xs",
    "jsx/ContextContentHeader/class/2" => "font-mono text-muted-foreground",
    "jsx/ContextContentHeader/class/3" => "space-y-2",
    "jsx/ContextContentHeader/class/4" => "bg-muted",
    "jsx/TokensWithCost/class/0" => "ml-2 text-muted-foreground"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `context_content_header` part."
  attr(:display_pct, :string, default: nil)
  attr(:total, :string, default: nil)
  attr(:used, :string, default: nil)
  attr(:used_percent, :string, default: nil)
  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_content_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextContentHeader/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <div class={upstream_fact("jsx/ContextContentHeader/class/1")}>
          <p>
            {@display_pct}
          </p>
          <p class={upstream_fact("jsx/ContextContentHeader/class/2")}>
            {@used} / {@total}
          </p>
        </div>
        <div class={upstream_fact("jsx/ContextContentHeader/class/3")}>
          <LiveShadcn.UI.Progress.progress value={@value} class={upstream_fact("jsx/ContextContentHeader/class/4")} />
        </div>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_content_body` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_content_body(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextContentBody/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_content_footer` part."
  attr(:total_cost, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_content_footer(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/ContextContentFooter/class/0"), (@class || "")]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <span class={upstream_fact("jsx/ContextCacheUsage/class/1")}>Total cost</span><span>{@total_cost}</span>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_input_usage` part."
  attr(:cost_text, :string, default: nil)
  attr(:input_cost_text, :string, default: nil)
  attr(:input_tokens, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_input_usage(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextCacheUsage/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/ContextCacheUsage/class/1")}>
        Input
      </span>
      <span>
        {if(is_nil(@input_tokens), do: "—", else: compact_number(@input_tokens))}
        <span :if={@input_cost_text} class={upstream_fact("jsx/TokensWithCost/class/0")}>
          • {@input_cost_text}
        </span>
        {nil}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_output_usage` part."
  attr(:cost_text, :string, default: nil)
  attr(:output_cost_text, :string, default: nil)
  attr(:output_tokens, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_output_usage(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextCacheUsage/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/ContextCacheUsage/class/1")}>
        Output
      </span>
      <span>
        {if(is_nil(@output_tokens), do: "—", else: compact_number(@output_tokens))}
        <span :if={@output_cost_text} class={upstream_fact("jsx/TokensWithCost/class/0")}>
          • {@output_cost_text}
        </span>
        {nil}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_reasoning_usage` part."
  attr(:cost_text, :string, default: nil)
  attr(:reasoning_cost_text, :string, default: nil)
  attr(:reasoning_tokens, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_reasoning_usage(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextCacheUsage/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/ContextCacheUsage/class/1")}>
        Reasoning
      </span>
      <span>
        {if(is_nil(@reasoning_tokens), do: "—", else: compact_number(@reasoning_tokens))}
        <span :if={@reasoning_cost_text} class={upstream_fact("jsx/TokensWithCost/class/0")}>
          • {@reasoning_cost_text}
        </span>
        {nil}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `context_cache_usage` part."
  attr(:cache_cost_text, :string, default: nil)
  attr(:cache_tokens, :any, default: nil)
  attr(:cost_text, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def context_cache_usage(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ContextCacheUsage/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/ContextCacheUsage/class/1")}>
        Cache
      </span>
      <span>
        {if(is_nil(@cache_tokens), do: "—", else: compact_number(@cache_tokens))}
        <span :if={@cache_cost_text} class={upstream_fact("jsx/TokensWithCost/class/0")}>
          • {@cache_cost_text}
        </span>
        {nil}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc false
  defp compact_number(number) when is_number(number) do
    {value, suffix} = compact_parts(number)
    whole = trunc(value)

    if value == whole, do: "#{whole}#{suffix}", else: "#{value}#{suffix}"
  end

  defp compact_number(_number), do: nil

  defp compact_parts(number) do
    {value, suffix} =
      cond do
        abs(number) >= 1.0e9 -> {number / 1.0e9, "B"}
        abs(number) >= 1.0e6 -> {number / 1.0e6, "M"}
        abs(number) >= 1.0e3 -> {number / 1.0e3, "K"}
        true -> {number * 1.0, ""}
      end

    rounded = Float.round(value, if(abs(value) < 10, do: 1, else: 0))

    if abs(rounded) >= 1000 and suffix != "B",
      do: compact_parts(round(rounded * 1000)),
      else: {rounded, suffix}
  end
end

defmodule LiveShadcn.UI.Bubble do
  @moduledoc """
  Bubble.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/bubbleReactionsVariants/base" => "cn-bubble-reactions absolute z-10 flex w-fit items-center justify-center",
    "cva/bubbleReactionsVariants/default/align" => "end",
    "cva/bubbleReactionsVariants/default/side" => "bottom",
    "cva/bubbleReactionsVariants/variant/align/end" => "cn-bubble-reactions-align-end",
    "cva/bubbleReactionsVariants/variant/align/start" => "cn-bubble-reactions-align-start",
    "cva/bubbleReactionsVariants/variant/side/bottom" => "cn-bubble-reactions-side-bottom",
    "cva/bubbleReactionsVariants/variant/side/top" => "cn-bubble-reactions-side-top",
    "cva/bubbleVariants/base" => "cn-bubble group/bubble relative flex w-fit min-w-0 flex-col",
    "cva/bubbleVariants/default/variant" => "default",
    "cva/bubbleVariants/variant/variant/default" => "cn-bubble-variant-default",
    "cva/bubbleVariants/variant/variant/destructive" => "cn-bubble-variant-destructive",
    "cva/bubbleVariants/variant/variant/ghost" => "cn-bubble-variant-ghost",
    "cva/bubbleVariants/variant/variant/muted" => "cn-bubble-variant-muted",
    "cva/bubbleVariants/variant/variant/outline" => "cn-bubble-variant-outline",
    "cva/bubbleVariants/variant/variant/secondary" => "cn-bubble-variant-secondary",
    "cva/bubbleVariants/variant/variant/tinted" => "cn-bubble-variant-tinted",
    "jsx/BubbleContent/class/0" => "cn-bubble-content w-fit max-w-full min-w-0 overflow-hidden wrap-break-word [button]:text-left [button,a]:transition-colors",
    "jsx/BubbleGroup/class/0" => "cn-bubble-group flex min-w-0 flex-col"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                       [table, "variant", group, choice] <- [String.split(path, "/")],
                       reduce: %{} do
    variants ->
      put_in(
        variants,
        [
          Access.key(table, %{}),
          Access.key(group, %{}),
          Access.key(choice, nil)
        ],
        value
      )
  end)

  @doc "The `bubble-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def bubble_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "bubble-group"}
      class={[upstream_fact("jsx/BubbleGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `bubble` part."
  attr(:align, :string, default: "start", values: ["start", "end"])

  attr(:variant, :string,
    default: @upstream_facts["cva/bubbleVariants/default/variant"],
    values: @variant_classes |> get_in(["bubbleVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def bubble(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "bubble"}
      data-variant={@variant}
      data-align={@align}
      class={[
        variant_class("bubbleVariants", "variant", @variant),
        upstream_fact("cva/bubbleVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `bubble-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def bubble_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "bubble-content"}
      class={[
        upstream_fact("jsx/BubbleContent/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `bubble-reactions` part."
  attr(:align, :string,
    default: @upstream_facts["cva/bubbleReactionsVariants/default/align"],
    values:
      @variant_classes
      |> get_in(["bubbleReactionsVariants", "align"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:side, :string,
    default: @upstream_facts["cva/bubbleReactionsVariants/default/side"],
    values:
      @variant_classes |> get_in(["bubbleReactionsVariants", "side"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def bubble_reactions(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "bubble-reactions"}
      data-align={@align}
      data-side={@side}
      class={[
        variant_class("bubbleReactionsVariants", "align", @align),
        variant_class("bubbleReactionsVariants", "side", @side),
        upstream_fact("cva/bubbleReactionsVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end
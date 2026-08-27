defmodule LiveShadcn.UI.ButtonGroup do
  @moduledoc """
  Button group.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/buttonGroupVariants/base" =>
      "cn-button-group flex w-fit items-stretch *:focus-visible:relative *:focus-visible:z-10 [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1",
    "cva/buttonGroupVariants/default/orientation" => "horizontal",
    "cva/buttonGroupVariants/variant/orientation/horizontal" =>
      "cn-button-group-orientation-horizontal *:data-slot:rounded-r-none [&>[data-slot]~[data-slot]]:rounded-l-none [&>[data-slot]~[data-slot]]:border-l-0",
    "cva/buttonGroupVariants/variant/orientation/vertical" =>
      "cn-button-group-orientation-vertical flex-col *:data-slot:rounded-b-none [&>[data-slot]~[data-slot]]:rounded-t-none [&>[data-slot]~[data-slot]]:border-t-0",
    "jsx/ButtonGroupSeparator/class/0" =>
      "cn-button-group-separator relative self-stretch data-horizontal:mx-px data-horizontal:w-auto data-vertical:my-px data-vertical:h-auto",
    "jsx/ButtonGroupText/class/0" =>
      "cn-button-group-text flex items-center [&_svg]:pointer-events-none"
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

  @doc "The `button-group` part."
  attr(:orientation, :string,
    default: @upstream_facts["cva/buttonGroupVariants/default/orientation"],
    values:
      @variant_classes
      |> get_in(["buttonGroupVariants", "orientation"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def button_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "button-group"}
      role="group"
      data-orientation={@orientation}
      class={[
        variant_class("buttonGroupVariants", "orientation", @orientation),
        upstream_fact("cva/buttonGroupVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `button-group-separator` part."
  attr(:orientation, :string, default: "vertical")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def button_group_separator(assigns) do
    ~H"""
    <LiveShadcn.UI.Separator.separator
      data-slot={@rest[:"data-slot"] || "button-group-separator"}
      orientation={@orientation}
      class={[
        upstream_fact("jsx/ButtonGroupSeparator/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Separator.separator>
    """
  end

  @doc "The `button-group-text` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def button_group_text(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "button-group-text"}
      class={[upstream_fact("jsx/ButtonGroupText/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end
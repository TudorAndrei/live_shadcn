defmodule LiveShadcn.UI.Button do
  @moduledoc """
  Button. A button component that can be used to trigger actions.

  Reviewed from shadcn/ui. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/buttonVariants/base" =>
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "cva/buttonVariants/default/size" => "default",
    "cva/buttonVariants/default/variant" => "default",
    "cva/buttonVariants/variant/size/default" => "cn-button-size-default",
    "cva/buttonVariants/variant/size/icon" => "cn-button-size-icon",
    "cva/buttonVariants/variant/size/icon-lg" => "cn-button-size-icon-lg",
    "cva/buttonVariants/variant/size/icon-sm" => "cn-button-size-icon-sm",
    "cva/buttonVariants/variant/size/icon-xs" => "cn-button-size-icon-xs",
    "cva/buttonVariants/variant/size/lg" => "cn-button-size-lg",
    "cva/buttonVariants/variant/size/sm" => "cn-button-size-sm",
    "cva/buttonVariants/variant/size/xs" => "cn-button-size-xs",
    "cva/buttonVariants/variant/variant/default" => "cn-button-variant-default",
    "cva/buttonVariants/variant/variant/destructive" => "cn-button-variant-destructive",
    "cva/buttonVariants/variant/variant/ghost" => "cn-button-variant-ghost",
    "cva/buttonVariants/variant/variant/link" => "cn-button-variant-link",
    "cva/buttonVariants/variant/variant/outline" => "cn-button-variant-outline",
    "cva/buttonVariants/variant/variant/secondary" => "cn-button-variant-secondary"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  @size_values for {"cva/buttonVariants/variant/size/" <> value, _class} <- @upstream_facts,
                   do: value

  @variant_values for {"cva/buttonVariants/variant/variant/" <> value, _class} <-
                        @upstream_facts,
                      do: value

  @doc "The `button` part."
  attr(:size, :string,
    default: @upstream_facts["cva/buttonVariants/default/size"],
    values: Enum.sort(@size_values)
  )

  attr(:variant, :string,
    default: @upstream_facts["cva/buttonVariants/default/variant"],
    values: Enum.sort(@variant_values)
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      class={[
        variant_class("buttonVariants", "size", @size),
        variant_class("buttonVariants", "variant", @variant),
        upstream_fact("cva/buttonVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  def part_class("button"), do: upstream_fact("cva/buttonVariants/base")

  def variant_class(table, group, value),
    do: Map.get(@upstream_facts, "cva/#{table}/variant/#{group}/#{value}")

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)
end

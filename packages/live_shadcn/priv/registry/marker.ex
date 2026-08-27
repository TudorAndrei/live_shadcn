defmodule LiveShadcn.UI.Marker do
  @moduledoc """
  Marker.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/markerVariants/base" => "cn-marker group/marker relative flex w-full items-center",
    "cva/markerVariants/variant/variant/border" => "cn-marker-variant-border",
    "cva/markerVariants/variant/variant/default" => "cn-marker-variant-default",
    "cva/markerVariants/variant/variant/separator" => "cn-marker-variant-separator",
    "jsx/MarkerContent/class/0" => "cn-marker-content min-w-0 wrap-break-word",
    "jsx/MarkerIcon/class/0" => "cn-marker-icon shrink-0"
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

  @doc "The `marker` part."
  attr(:variant, :string,
    default: "default",
    values: @variant_classes |> get_in(["markerVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def marker(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "marker"}
      data-variant={@variant}
      class={[
        variant_class("markerVariants", "variant", @variant),
        upstream_fact("cva/markerVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `marker-icon` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def marker_icon(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "marker-icon"}
      aria-hidden="true"
      class={[upstream_fact("jsx/MarkerIcon/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `marker-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def marker_content(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "marker-content"}
      class={[upstream_fact("jsx/MarkerContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end
defmodule LiveShadcn.UI.Label do
  @moduledoc """
  Label.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Label/class/0" =>
      "cn-label flex items-center select-none group-data-[disabled=true]:pointer-events-none peer-disabled:cursor-not-allowed"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `label` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "for"])
  slot(:inner_block)

  def label(assigns) do
    assigns =
      assign(assigns, :label_id, assigns.rest[:id] || label_id(assigns.rest[:for]))

    ~H"""
    <label
      id={@label_id}
      data-slot={@rest[:"data-slot"] || "label"}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/Label/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot", :id])}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end

  defp label_id(nil), do: nil
  defp label_id(for_id), do: "#{for_id}-label"
end

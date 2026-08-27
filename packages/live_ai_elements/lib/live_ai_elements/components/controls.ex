defmodule LiveAiElements.Components.Controls do
  @moduledoc """
  Controls.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "port/class/0" =>
      "gap-px overflow-hidden rounded-md border bg-card p-1 shadow-none! [&>button]:rounded-md [&>button]:border-none! [&>button]:bg-transparent! [&>button]:hover:bg-secondary!"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `controls` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def controls(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end

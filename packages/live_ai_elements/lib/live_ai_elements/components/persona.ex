defmodule LiveAiElements.Components.Persona do
  @moduledoc """
  Persona.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/anonymous/class/0" => "size-16 shrink-0"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `persona` part."
  attr(:rive, :string, default: nil)
  attr(:source, :string, default: nil)
  attr(:state, :string, default: "idle")
  attr(:variant, :string, default: "obsidian")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def persona(assigns) do
    ~H"""
    <canvas class={[upstream_fact("jsx/anonymous/class/0"), (@class || "")]} />
    {render_slot(@inner_block)}
    """
  end
end

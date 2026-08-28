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

  @sources %{
    "command" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/command-2.0.riv",
    "glint" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/glint-2.0.riv",
    "halo" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/halo-2.0.riv",
    "mana" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/mana-2.0.riv",
    "obsidian" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/obsidian-2.0.riv",
    "opal" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/orb-1.2.riv"
  }

  @doc "The `persona` part."
  attr(:id, :string, required: true)
  attr(:rive, :string, default: nil)
  attr(:source, :string, default: nil)
  attr(:state, :string, default: "idle")
  attr(:variant, :string, default: "obsidian", values: Map.keys(@sources) |> Enum.sort())
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def persona(assigns) do
    assigns =
      assign(assigns, :rive_source, assigns.source || assigns.rive || @sources[assigns.variant])

    ~H"""
    <div
      id={@id}
      data-persona-state={@state}
      data-persona-variant={@variant}
      data-rive-source={@rive_source}
      phx-hook="LiveAiElements.Persona"
      class={[upstream_fact("jsx/anonymous/class/0"), @class || ""]}
      {@rest}
    >
      <canvas data-persona-canvas />
    </div>
    {render_slot(@inner_block)}
    """
  end
end

defmodule LiveShadcn.UI.Kbd do
  @moduledoc """
  Kbd.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Kbd/class/0" =>
      "cn-kbd pointer-events-none inline-flex items-center justify-center select-none",
    "jsx/KbdGroup/class/0" => "cn-kbd-group inline-flex items-center"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `kbd` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def kbd(assigns) do
    ~H"""
    <kbd
      data-slot={@rest[:"data-slot"] || "kbd"}
      class={[
        upstream_fact("jsx/Kbd/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  @doc "The `kbd-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def kbd_group(assigns) do
    ~H"""
    <kbd
      data-slot={@rest[:"data-slot"] || "kbd-group"}
      class={[upstream_fact("jsx/KbdGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end
end
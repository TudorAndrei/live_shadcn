defmodule LiveShadcn.UI.NativeSelect do
  @moduledoc """
  Native select.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/NativeSelect/class/0" => "cn-native-select-wrapper group/native-select relative w-fit has-[select:disabled]:opacity-50",
    "jsx/NativeSelect/class/1" => "cn-native-select outline-none disabled:pointer-events-none disabled:cursor-not-allowed",
    "jsx/NativeSelect/class/2" => "cn-native-select-icon pointer-events-none absolute select-none",
    "jsx/NativeSelectOptGroup/class/0" => "bg-[Canvas] text-[CanvasText]"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `native-select-wrapper` part."
  attr(:size, :string, default: "default", values: ["sm", "default"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "name", "multiple", "size", "disabled", "required"])
  slot(:inner_block)

  def native_select(assigns) do
    ~H"""
    <div
      data-slot="native-select-wrapper"
      data-size={@size}
      class={[
        upstream_fact("jsx/NativeSelect/class/0"),
        (@class || "")
      ]}
    >
      <select
        data-slot={@rest[:"data-slot"] || "native-select"}
        data-size={@size}
        class={upstream_fact("jsx/NativeSelect/class/1")}
        {Map.drop(@rest, [:"data-slot"])}
      >
        {render_slot(@inner_block)}
      </select>
      <LiveShadcn.Icon.icon
        name="chevron-down"
        data-slot="native-select-icon"
        class={upstream_fact("jsx/NativeSelect/class/2")}
      />
    </div>
    """
  end

  @doc "The `native-select-optgroup` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def native_select_opt_group(assigns) do
    ~H"""
    <optgroup
      data-slot={@rest[:"data-slot"] || "native-select-optgroup"}
      class={[upstream_fact("jsx/NativeSelectOptGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </optgroup>
    """
  end

  @doc "The `native-select-option` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "value", "selected"])
  slot(:inner_block)

  def native_select_option(assigns) do
    ~H"""
    <option
      data-slot={@rest[:"data-slot"] || "native-select-option"}
      class={[upstream_fact("jsx/NativeSelectOptGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </option>
    """
  end
end
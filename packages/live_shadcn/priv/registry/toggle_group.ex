defmodule LiveShadcn.UI.ToggleGroup do
  @moduledoc false

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ToggleGroup/class/0" =>
      "cn-toggle-group group/toggle-group flex w-fit flex-row items-center gap-[--spacing(var(--gap))] data-vertical:flex-col data-vertical:items-stretch",
    "jsx/ToggleGroupItem/class/0" =>
      "cn-toggle-group-item shrink-0 focus:z-10 focus-visible:z-10 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:orientation, :string, default: "horizontal")
  attr(:size, :string, default: nil)
  attr(:spacing, :integer, default: 2)
  attr(:variant, :string, default: nil)
  attr(:multiple, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:output, :string, default: nil, doc: "A selector whose text receives the selected value.")
  attr(:output_prefix, :string, default: "")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])

  slot :item do
    attr(:id, :string)
    attr(:name, :string)
    attr(:checked, :boolean)
    attr(:disabled, :boolean)
    attr(:readonly, :boolean)
    attr(:value, :string)
    attr(:native_value, :string)
    attr(:class, :any)
    attr(:variant, :string)
    attr(:size, :string)
    attr(:on_click, :any)
    attr(:"aria-label", :string)
  end

  def toggle_group(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot={@rest[:"data-slot"] || "toggle-group"}
      role="group"
      phx-hook={LiveBase.ToggleGroup.hook()}
      data-variant={@variant}
      data-size={@size}
      data-spacing={@spacing}
      data-orientation={@orientation}
      data-horizontal={flag(@orientation == "horizontal")}
      data-vertical={flag(@orientation == "vertical")}
      data-multiple={flag(@multiple)}
      data-disabled={flag(@disabled)}
      data-lb-output={@output}
      data-lb-output-prefix={@output_prefix}
      style={"--gap: #{@spacing}"}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/ToggleGroup/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.UI.Toggle.toggle
        :for={item <- @item}
        id={item[:id] || "#{@id}-#{item[:value]}"}
        name={item[:name]}
        value={item[:native_value]}
        data-lb-value={item[:value]}
        checked={item[:checked]}
        disabled={@disabled || item[:disabled] || false}
        aria-disabled={to_string(@disabled || item[:disabled] || false)}
        readonly={item[:readonly] || false}
        variant={@variant || item[:variant] || "default"}
        size={@size || item[:size] || "default"}
        on_click={
          item[:on_click] ||
            JS.dispatch("live-base:toggle-group",
              to: "##{@id}",
              detail: %{item: item[:id] || "#{@id}-#{item[:value]}"}
            )
        }
        aria-label={item[:"aria-label"]}
        data-slot="toggle-group-item"
        data-variant={@variant || item[:variant] || "default"}
        data-size={@size || item[:size] || "default"}
        data-spacing={@spacing}
        class={[
          upstream_fact("jsx/ToggleGroupItem/class/0"),
          item[:class]
        ]}
      >
        {render_slot(item)}
      </LiveShadcn.UI.Toggle.toggle>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_value), do: nil
end

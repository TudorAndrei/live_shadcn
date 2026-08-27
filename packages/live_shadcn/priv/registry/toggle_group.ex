defmodule LiveShadcn.UI.ToggleGroup do
  @moduledoc false

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ToggleGroup/class/0" => "cn-toggle-group group/toggle-group flex w-fit flex-row items-center gap-[--spacing(var(--gap))] data-vertical:flex-col data-vertical:items-stretch",
    "jsx/ToggleGroupItem/class/0" => "cn-toggle-group-item shrink-0 focus:z-10 focus-visible:z-10 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  attr(:orientation, :string, default: "horizontal")
  attr(:size, :string, default: nil)
  attr(:spacing, :string, default: "2")
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])

  slot :item do
    attr(:id, :string)
    attr(:name, :string)
    attr(:checked, :boolean)
    attr(:disabled, :boolean)
    attr(:readonly, :boolean)
    attr(:value, :string)
    attr(:class, :any)
    attr(:variant, :string)
    attr(:size, :string)
    attr(:"aria-label", :string)
  end

  def toggle_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "toggle-group"}
      data-variant={@variant}
      data-size={@size}
      data-spacing={@spacing}
      data-orientation={@orientation}
      style={"--gap: #{@spacing}"}
      class={[
        upstream_fact("jsx/ToggleGroup/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.UI.Toggle.toggle
        :for={item <- @item}
        id={item[:id]}
        name={item[:name]}
        value={item[:value] || "true"}
        checked={item[:checked]}
        disabled={item[:disabled] || false}
        readonly={item[:readonly] || false}
        variant={@variant || item[:variant] || "default"}
        size={@size || item[:size] || "default"}
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
end

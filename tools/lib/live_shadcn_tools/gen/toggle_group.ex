defmodule LiveShadcnTools.Gen.ToggleGroup do
  @moduledoc """
  The toggle-group recipe.

  React context gives each item the group variant and size. A LiveView function
  component cannot pass assigns into separately called child components, so the
  group takes item slots and renders the existing toggle control itself.
  """

  alias LiveShadcnTools.Gen.Heex

  @doc "The module source for one toggle group component."
  def module(spec, opts) do
    root = Enum.find(spec["parts"], &(&1["name"] == "toggle_group"))
    item = Enum.find(spec["parts"], &(&1["name"] == "toggle_group_item"))

    root_markup =
      Heex.render(Heex.with_children(root["tree"]), %{
        attrs: %{},
        props: %{},
        children: items_markup(item),
        class: "@class",
        params: root["params"] || %{},
        contexts: root["contexts"] || [],
        variants: spec["variants"] || %{},
        client_attributes: [],
        hook_part: nil,
        rest: true
      })

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
      @moduledoc false

      use Phoenix.Component

      attr :orientation, :string, default: "horizontal"
      attr :size, :string, default: nil
      attr :spacing, :string, default: "2"
      attr :variant, :string, default: nil
      attr :class, :any, default: nil
      attr :rest, :global, include: ["data-slot"]

      slot :item do
        attr :id, :string
        attr :name, :string
        attr :checked, :boolean
        attr :disabled, :boolean
        attr :readonly, :boolean
        attr :value, :string
        attr :class, :any
        attr :variant, :string
        attr :size, :string
        attr :"aria-label", :string
      end

      def toggle_group(assigns) do
        ~H\"\"\"
    #{root_markup}
        \"\"\"
      end
    end
    """
  end

  defp items_markup(item) do
    class = inspect(item["tree"]["class"])

    """
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
            class={[#{class}, item[:class]]}
          >
            {render_slot(item)}
          </LiveShadcn.UI.Toggle.toggle>
    """
  end
end

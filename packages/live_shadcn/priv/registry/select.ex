defmodule LiveShadcn.UI.Select do
  @moduledoc """
  Select. Groups all parts of the select.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/SelectContent/class/0" => "isolate z-50",
    "jsx/SelectContent/class/1" =>
      "cn-select-content cn-select-content-logical cn-menu-target cn-menu-translucent relative isolate z-50 max-h-(--available-height) w-(--anchor-width) origin-(--transform-origin) overflow-x-hidden overflow-y-auto data-[align-trigger=true]:animate-none",
    "jsx/SelectGroup/class/0" => "cn-select-group",
    "jsx/SelectItem/class/0" =>
      "cn-select-item relative flex w-full cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/SelectItem/class/1" => "cn-select-item-text shrink-0 whitespace-nowrap",
    "jsx/SelectItem/class/2" => "cn-select-item-indicator",
    "jsx/SelectItem/class/3" => "cn-select-item-indicator-icon pointer-events-none",
    "jsx/SelectLabel/class/0" => "cn-select-label",
    "jsx/SelectScrollDownButton/class/0" => "cn-select-scroll-down-button bottom-0 w-full",
    "jsx/SelectScrollUpButton/class/0" => "cn-select-scroll-up-button top-0 w-full",
    "jsx/SelectSeparator/class/0" => "cn-select-separator pointer-events-none",
    "jsx/SelectTrigger/class/0" =>
      "cn-select-trigger flex w-fit items-center justify-between whitespace-nowrap outline-none disabled:cursor-not-allowed disabled:opacity-50 *:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/SelectTrigger/class/1" => "cn-select-trigger-icon pointer-events-none",
    "jsx/SelectValue/class/0" => "cn-select-value"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.FormControl
  alias LiveBase.Listbox
  alias LiveBase.Popover
  alias Phoenix.LiveView.JS

  @doc """
  Groups all parts of the select.

      <.select id="style" field={@form[:style]}>
        <:option value="vega" label="Vega" />
        <:option value="nova" label="Nova" />
      </.select>

  The trigger is a button, and a button submits nothing, so there is a hidden
  input beside it carrying the chosen value. Choosing runs on the client and
  fires `change`, so `phx-change` still sees it.
  """
  attr(:id, :string, required: true, doc: "Every id inside the listbox derives from it.")

  attr(:trigger_id, :string,
    default: nil,
    doc: "The id of the trigger button. Defaults to the id derived from `:id`."
  )

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
  )

  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "The chosen value.")

  attr(:placeholder, :string,
    default: "Select…",
    doc: "What the trigger reads with nothing chosen."
  )

  attr(:labelledby, :string, default: nil, doc: "The id of the label that names it.")
  attr(:errors, :list, default: [])
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:class, :any, default: nil, doc: "Appended to the list's class string.")
  attr(:label_class, :any, default: nil)
  attr(:item_class, :any, default: nil)
  attr(:separator_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:value_class, :any, default: nil)

  attr(:value_as_text, :boolean,
    default: false,
    doc:
      "Emits the selected value as direct trigger text for a caller-rendered SelectTrigger composition."
  )

  attr(:align_item_with_trigger, :boolean, default: true)
  attr(:align_offset, :integer, default: 0)
  attr(:side_offset, :integer, default: 4)
  attr(:size, :string, default: "default", values: ["sm", "default"])
  attr(:dir, :string, default: nil, values: [nil, "ltr", "rtl"])
  attr(:content_lang, :string, default: nil)
  attr(:rest, :global)

  slot :option, doc: "One value to choose." do
    attr(:value, :string, required: true, doc: "Unique. What the form submits.")
    attr(:label, :string, doc: "What it reads. Defaults to the value.")
    attr(:description, :string, doc: "Muted text shown beside the item label.")
    attr(:trigger_label, :string, doc: "Optional text for this value in the closed trigger.")
    attr(:disabled, :boolean)
  end

  slot :group, doc: "A labelled or unlabelled group of options." do
    attr(:label, :string)
    attr(:options, :list, required: true)
    attr(:separator, :boolean)
  end

  slot(:inner_block, doc: "Anything the options do not cover.")

  def select(assigns) do
    assigns = FormControl.from_field(assigns)

    groups = groups(assigns.group, assigns.option)

    assigns =
      assigns
      |> assign(:groups, groups)
      |> assign(:options, Enum.flat_map(groups, & &1.options))
      |> assign(:trigger_id, assigns.trigger_id || Popover.trigger_id(assigns.id))
      |> assign(
        :selected_label,
        label(Enum.flat_map(groups, & &1.options), assigns.value) || assigns.placeholder
      )
      |> assign(:trigger_aria_label, assigns.rest[:"aria-label"])
      |> assign(:trigger_labelledby, assigns.labelledby || assigns.rest[:"aria-labelledby"])
      |> assign(:trigger_rest, Map.drop(assigns.rest, [:"aria-label", :"aria-labelledby"]))

    ~H"""
    <button
      data-slot="select-trigger"
      id={@trigger_id}
      type="button"
      disabled={@disabled}
      role="combobox"
      aria-labelledby={@trigger_labelledby || if(is_nil(@trigger_aria_label), do: Listbox.value_id(@id))}
      aria-label={@trigger_aria_label}
      aria-haspopup="listbox"
      aria-expanded={to_string(@open)}
      aria-controls={if(@open, do: "#{@id}-list")}
      phx-click={if(not @disabled, do: toggle(@id, @trigger_id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      phx-window-keydown={close(@id, @trigger_id)}
      phx-key="Escape"
      data-popup-open={flag(@open)}
      data-pressed={flag(@open)}
      data-disabled={flag(@disabled)}
      data-readonly={flag(@readonly)}
      data-required={flag(@required)}
      data-valid={flag(@errors == [])}
      data-invalid={flag(@errors != [])}
      data-filled={flag(@value not in [nil, ""])}
      data-placeholder={flag(@value in [nil, ""])}
      aria-invalid={if(@errors != [], do: "true")}
      aria-readonly={if(@readonly, do: "true")}
      aria-required={if(@required, do: "true")}
      data-size={@size}
      dir={@dir}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/SelectTrigger/class/0"), @trigger_class])}
      {@trigger_rest}
    >
      <span
        data-slot={if(not @value_as_text, do: "select-value")}
        id={Listbox.value_id(@id)}
        data-label={@selected_label}
        data-placeholder={flag(@value in [nil, ""])}
        phx-hook="LiveBase.ListboxValue"
        phx-mounted={Listbox.owned_attributes(:value)}
        class={if(@value_as_text, do: "contents", else: [upstream_fact("jsx/SelectValue/class/0"), @value_class])}
      >
        {@selected_label}
      </span>
      <LiveShadcn.Icon.icon name="chevron-down" class={upstream_fact("jsx/SelectTrigger/class/1")} />
    </button>
    <input
      id={Listbox.input_id(@id)}
      name={@name}
      value={@value}
      disabled={@disabled}
      required={@required}
      aria-hidden="true"
      tabindex="-1"
      style={hidden_input_style(not is_nil(@name))}
      phx-mounted={Listbox.owned_attributes(:input)}
    />
    <.portal id={"#{@id}-portal"} target="body">
      <div
        id={Popover.positioner_id(@id)}
        hidden={not @open}
        phx-hook={Popover.hook()}
        phx-click-away={close(@id, @trigger_id)}
        data-lb-anchor={@trigger_id}
        data-lb-side={@side}
        data-lb-align={@align}
        data-lb-offset={to_string(@side_offset)}
        data-lb-align-offset={to_string(@align_offset)}
        data-lb-align-item={flag(@align_item_with_trigger)}
        data-lb-autofocus
        phx-mounted={Popover.owned_attributes(:positioner)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={upstream_fact("jsx/SelectContent/class/0")}
      >
        <div
          data-slot="select-content"
          id={Popover.popup_id(@id)}
          role="presentation"
          tabindex="0"
          hidden={not @open}
          data-lb-popup
          phx-hook="LiveBase.Roving"
          data-lb-roving="option"
          data-lb-orientation="vertical"
          data-lb-highlight="data-highlighted"
          data-lb-initial-highlight
          phx-mounted={Popover.owned_attributes(:popup)}
          data-open={flag(@open)}
          data-closed={flag(not @open)}
          data-align-trigger={to_string(@align_item_with_trigger)}
          dir={@dir}
          data-lang={@content_lang}
          class={[
            upstream_fact("jsx/SelectContent/class/1"),
            @class || ""
          ]}
          data-lb-style-target
          data-lb-measure
        >
          <div
            data-slot="select-scroll-up-button"
            hidden
            aria-hidden="true"
            style="position: absolute;"
            class={[upstream_fact("jsx/SelectScrollUpButton/class/0"), @class || ""]}
          >
            <LiveShadcn.Icon.icon name="chevron-up" />
          </div>
          <div id={"#{@id}-list"} role="listbox">
            <%= for {group, group_index} <- Enum.with_index(@groups) do %>
              <div
                :if={group.separator}
                data-slot="select-separator"
                role="presentation"
                class={[
                  upstream_fact("jsx/SelectSeparator/class/0"),
                  @separator_class || ""
                ]}
              />
              <div
                data-slot="select-group"
                role="group"
                aria-labelledby={if(group.label, do: "#{@id}-group-#{group_index}-label")}
                class={upstream_fact("jsx/SelectGroup/class/0")}
              >
                <div
                  :if={group.label}
                  id={"#{@id}-group-#{group_index}-label"}
                  data-slot="select-label"
                  class={upstream_fact("jsx/SelectLabel/class/0")}
                >
                  {group.label}
                </div>
                <div
                  :for={option <- group.options}
                  data-slot="select-item"
                  id={Listbox.option_id(@id, option[:value])}
                  role="option"
                  tabindex="-1"
                  aria-selected={to_string(selected?(option[:value], @value))}
                  data-selected={flag(selected?(option[:value], @value))}
                  phx-click={
                    if(option[:disabled] != true,
                      do:
                        Listbox.choose(
                          listbox: @id,
                          trigger_id: @trigger_id,
                          value: option[:value],
                          label: option[:label]
                        )
                        |> JS.remove_attribute("aria-controls", to: "##{@trigger_id}")
                    )
                  }
                  phx-mounted={Listbox.owned_attributes(:option)}
                  data-disabled={flag(option[:disabled] == true)}
                  class={[
                    upstream_fact("jsx/SelectItem/class/0"),
                    @item_class || ""
                  ]}
                >
                  <div class={upstream_fact("jsx/SelectItem/class/1")}>
                    {option[:label] || option[:value]}
                    <span :if={option[:description]} class="text-muted-foreground">
                      {" "}{option[:description]}
                    </span>
                  </div>
                  <span
                    :if={selected?(option[:value], @value)}
                    class={upstream_fact("jsx/SelectItem/class/2")}
                  >
                    <LiveShadcn.Icon.icon
                      name="check"
                      class={upstream_fact("jsx/SelectItem/class/3")}
                    />
                  </span>
                </div>
              </div>
            <% end %>
          </div>
          <div
            data-slot="select-scroll-down-button"
            hidden
            aria-hidden="true"
            style="position: absolute;"
            class={[upstream_fact("jsx/SelectScrollDownButton/class/0"), @class || ""]}
          >
            <LiveShadcn.Icon.icon name="chevron-down" />
          </div>
        </div>
      </div>
    </.portal>
    """
  end

  # What the trigger reads before anything has been chosen, and after.
  defp label(options, value) do
    case Enum.find(options, &selected?(&1[:value], value)) do
      nil -> nil
      option -> option[:trigger_label] || option[:label] || option[:value]
    end
  end

  defp hidden_input_style(true),
    do:
      "clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0; padding: 0; width: 1px; height: 1px; margin: -1px; position: absolute;"

  defp hidden_input_style(false),
    do:
      "clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0; padding: 0; width: 1px; height: 1px; margin: -1px; position: fixed; top: 0; left: 0;"

  defp groups([], options), do: [%{label: nil, options: options, separator: false}]

  defp groups(groups, _options) do
    Enum.map(groups, fn group ->
      %{
        label: group[:label],
        options: group[:options] || [],
        separator: group[:separator] == true
      }
    end)
  end

  defp selected?(option_value, value) when option_value in [nil, ""] and value in [nil, ""],
    do: true

  defp selected?(option_value, value), do: option_value == value

  defp toggle(id, trigger_id) do
    Popover.toggle(%JS{}, id, trigger_id: trigger_id)
    |> JS.toggle_attribute({"aria-controls", "#{id}-list"}, to: "##{trigger_id}")
  end

  defp close(id, trigger_id) do
    Popover.close(%JS{}, id, trigger_id: trigger_id)
    |> JS.remove_attribute("aria-controls", to: "##{trigger_id}")
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end

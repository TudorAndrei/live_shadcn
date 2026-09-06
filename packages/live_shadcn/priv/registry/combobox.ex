defmodule LiveShadcn.UI.Combobox do
  @moduledoc """
  A filterable combobox.

  The component is composed from public parts. Its client state belongs to
  `LiveBase.Combobox`, while this file keeps the copied shadcn markup and
  classes self-contained.
  """

  use Phoenix.Component

  alias LiveBase.Combobox
  alias LiveBase.FormControl
  alias LiveBase.Popover

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ComboboxChip/class/0" =>
      "cn-combobox-chip has-disabled:pointer-events-none has-disabled:cursor-not-allowed has-disabled:opacity-50",
    "jsx/ComboboxChip/class/1" => "cn-combobox-chip-remove",
    "jsx/ComboboxChip/class/2" => "cn-combobox-chip-indicator-icon pointer-events-none",
    "jsx/ComboboxChips/class/0" => "cn-combobox-chips",
    "jsx/ComboboxChipsInput/class/0" => "cn-combobox-chip-input min-w-16 flex-1 outline-none",
    "jsx/ComboboxClear/class/0" => "cn-combobox-clear",
    "jsx/ComboboxClear/class/1" => "cn-combobox-clear-icon pointer-events-none",
    "jsx/ComboboxContent/class/0" => "isolate z-50",
    "jsx/ComboboxContent/class/1" =>
      "cn-combobox-content cn-combobox-content-logical cn-menu-target cn-menu-translucent group/combobox-content relative max-h-(--available-height) w-(--anchor-width) max-w-(--available-width) min-w-[calc(var(--anchor-width)+--spacing(7))] origin-(--transform-origin) data-[chips=true]:min-w-(--anchor-width)",
    "jsx/ComboboxEmpty/class/0" => "cn-combobox-empty",
    "jsx/ComboboxGroup/class/0" => "cn-combobox-group",
    "jsx/ComboboxInput/class/0" => "cn-combobox-input w-auto",
    "jsx/ComboboxInput/class/1" =>
      "group-has-data-[slot=combobox-clear]/input-group:hidden data-pressed:bg-transparent",
    "jsx/ComboboxItem/class/0" =>
      "cn-combobox-item relative flex w-full cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/ComboboxItem/class/1" => "cn-combobox-item-indicator",
    "jsx/ComboboxItem/class/2" => "cn-combobox-item-indicator-icon pointer-events-none",
    "jsx/ComboboxLabel/class/0" => "cn-combobox-label",
    "jsx/ComboboxList/class/0" => "cn-combobox-list overflow-y-auto overscroll-contain",
    "jsx/ComboboxSeparator/class/0" => "cn-combobox-separator",
    "jsx/ComboboxTrigger/class/0" => "cn-combobox-trigger",
    "jsx/ComboboxTrigger/class/1" => "cn-combobox-trigger-icon pointer-events-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp fact(key), do: Map.fetch!(@upstream_facts, key)

  defp input_group_class,
    do:
      "group/input-group cn-input-group relative flex min-w-0 items-center outline-none has-[>textarea]:h-auto"

  defp input_class,
    do:
      "cn-input w-full min-w-0 outline-none file:inline-flex file:border-0 file:bg-transparent file:text-foreground placeholder:text-muted-foreground disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50"

  defp input_group_input_class, do: "cn-input-group-input flex-1"

  # Base UI merges the trigger render prop before the InputGroupButton render
  # prop. Keep the resulting pinned class order here, rather than exposing a
  # new Button composition API from this copied registry module.
  defp combobox_trigger_button_class,
    do:
      "cn-combobox-trigger cn-button group/button shrink-0 justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-default cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs group-has-data-[slot=combobox-clear]/input-group:hidden data-pressed:bg-transparent"

  defp combobox_clear_button_class,
    do:
      "cn-button group/button shrink-0 justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-default cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs cn-combobox-clear"

  defp chip_remove_class,
    do:
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-icon-xs cn-combobox-chip-remove"

  @doc "The Combobox context. It renders no DOM. Bind `:let={combobox}` and pass the value to its visible anchor and content parts."
  attr(:id, :string, required: true)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:name, :string, default: nil)
  attr(:form, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:default_value, :any, default: nil)
  attr(:placeholder, :string, default: "Select…")
  attr(:labelledby, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:multiple, :boolean, default: false)
  attr(:auto_highlight, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)

  slot :option do
    attr(:value, :string, required: true)
    attr(:label, :string)
    attr(:disabled, :boolean)
  end

  slot(:inner_block)

  def combobox(assigns) do
    assigns = FormControl.from_field(assigns)
    values = initial_values(assigns.value || assigns.default_value, assigns.multiple)
    assigns = assign(assigns, :combobox, combobox_config(assigns, values))

    ~H"""
    <%= if @option != [] do %>
      <.combobox_input combobox_id={@combobox.id} combobox={@combobox} disabled={@combobox.disabled} placeholder={@placeholder} aria-labelledby={@labelledby} />
      <.combobox_content combobox_id={@combobox.id} combobox={@combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id={@combobox.id}>
          <.combobox_item :for={option <- @option} combobox_id={@combobox.id} value={option.value} disabled={option[:disabled]}>
            {option[:label] || option.value}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    <% end %>
    {render_slot(@inner_block, @combobox)}
    <input
      id={if(@combobox.multiple || is_nil(@combobox.name), do: "#{@combobox.id}-hidden-input")}
      type="text"
      data-lb-combobox-form-input={if(@combobox.name, do: @combobox.id)}
      data-lb-combobox-form-name={@combobox.name}
      form={@combobox.form}
      name={if(@combobox.multiple, do: nil, else: @combobox.name)}
      value={if(@combobox.multiple, do: "", else: List.first(@combobox.values) || "")}
      disabled={@combobox.disabled}
      required={@combobox.required and not (@combobox.multiple and @combobox.values != [])}
      readonly={@combobox.readonly}
      tabindex="-1"
      aria-hidden="true"
      style={hidden_input_style(not is_nil(@combobox.name) and not @combobox.multiple)}
      phx-mounted={Combobox.owned_attributes(:hidden_input)}
    />
    <input
      :for={value <- if(@combobox.multiple && @combobox.name, do: @combobox.values, else: [])}
      type="hidden"
      data-lb-combobox-form-value={@combobox.id}
      form={@combobox.form}
      name={@combobox.name}
      value={value}
      disabled={@combobox.disabled}
    />
    """
  end

  @doc "The editable Combobox input with its trigger and optional clear button."
  attr(:combobox_id, :string, required: true)
  attr(:combobox, :map, default: nil)
  attr(:id, :string, default: nil)

  attr(:controller, :boolean,
    default: true,
    doc: "Set false when a sibling `combobox_trigger/1` owns the hook."
  )

  attr(:placeholder, :string, default: nil)
  attr(:value, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:show_trigger, :boolean, default: true)
  attr(:show_clear, :boolean, default: false)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ["aria-invalid", "aria-label", "autocomplete", "name", "readonly", "required"]
  )

  slot(:inner_block)

  def combobox_input(assigns) do
    assigns = assign(assigns, :combobox, assigns.combobox || default_combobox_config(assigns))

    assigns =
      assign(
        assigns,
        :id,
        assigns.id ||
          if(assigns.controller, do: base_ui_input_id(), else: base_ui_popup_input_id())
      )

    ~H"""
    <div data-slot="input-group" role="group" class={[input_group_class(), fact("jsx/ComboboxInput/class/0"), @class]}>
      <input
        id={@id}
        data-slot="input-group-control"
        data-lb-combobox={if(@controller, do: "")}
        data-combobox-controller={@combobox.id}
        data-combobox-value={Enum.join(@combobox.values, <<31>>)}
        data-combobox-has-value={if(@combobox.has_value, do: "")}
        data-combobox-multiple={if(@combobox.multiple, do: "")}
        data-combobox-auto-highlight={if(@combobox.auto_highlight, do: "")}
        data-readonly={flag(@combobox.readonly)}
        data-required={flag(@combobox.required)}
        data-valid=""
        phx-hook={if(@controller, do: Combobox.hook())}
        phx-mounted={
          if(@controller,
            do: Combobox.owned_attributes(:root) |> Combobox.owned_attributes(:input),
            else: Combobox.owned_attributes(:input)
          )
        }
        role="combobox"
        type="text"
        autocomplete={@rest[:autocomplete] || "off"}
        aria-autocomplete="list"
        aria-expanded="false"
        aria-haspopup="listbox"
        placeholder={@placeholder}
        value={@value}
        disabled={@combobox.disabled || @disabled}
        readonly={@rest[:readonly]}
        required={@rest[:required]}
        data-disabled={flag(@combobox.disabled || @disabled)}
        class={[input_class(), input_group_input_class()]}
        {Map.drop(@rest, [:autocomplete, :readonly, :required])}
      />
      <div
        data-slot="input-group-addon"
        role="group"
        data-align="inline-end"
        phx-mounted={Combobox.owned_attributes(:addon)}
        class="cn-input-group-addon flex cursor-text items-center justify-center select-none cn-input-group-addon-align-inline-end order-last"
      >
        <button
          :if={@show_trigger}
          data-slot="input-group-button"
          data-placeholder=""
          data-size="icon-xs"
          type="button"
          tabindex="0"
          aria-expanded="false"
          aria-haspopup="listbox"
          disabled={@combobox.disabled || @disabled}
          phx-mounted={Combobox.owned_attributes(:trigger)}
          class={combobox_trigger_button_class()}
        >
          <LiveShadcn.Icon.icon name="chevron-down" class={fact("jsx/ComboboxTrigger/class/1")} />
        </button>
        <.combobox_clear
          :if={@show_clear}
          combobox_id={@combobox.id}
          disabled={@combobox.disabled || @disabled}
          visible={@combobox.values != []}
        />
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A button trigger for the input-inside-popup pattern."
  attr(:combobox_id, :string, required: true)
  attr(:combobox, :map, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["aria-label", "data-slot"])
  slot(:inner_block)

  def combobox_trigger(assigns) do
    assigns = assign(assigns, :combobox, assigns.combobox || default_combobox_config(assigns))

    ~H"""
    <button
      id={base_ui_input_id()}
      data-slot={@rest[:"data-slot"] || "combobox-trigger"}
      type="button"
      data-lb-combobox
      data-combobox-controller={@combobox.id}
      data-combobox-value={Enum.join(@combobox.values, <<31>>)}
      data-combobox-has-value={if(@combobox.has_value, do: "")}
      data-combobox-multiple={if(@combobox.multiple, do: "")}
      data-combobox-auto-highlight={if(@combobox.auto_highlight, do: "")}
      data-disabled={flag(@combobox.disabled || @disabled)}
      data-readonly={flag(@combobox.readonly)}
      data-required={flag(@combobox.required)}
      data-valid=""
      role="combobox"
      aria-expanded="false"
      aria-haspopup="dialog"
      disabled={@combobox.disabled || @disabled}
      phx-hook={Combobox.hook()}
      phx-mounted={Combobox.owned_attributes(:root)}
      class={[@class, fact("jsx/ComboboxTrigger/class/0")]}
      {Map.drop(@rest, [:"data-slot", :id])}
    >
      {render_slot(@inner_block)}
      <LiveShadcn.Icon.icon name="chevron-down" class={fact("jsx/ComboboxTrigger/class/1")} />
    </button>
    """
  end

  @doc "The selected Combobox value."
  slot(:inner_block)

  def combobox_value(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  @doc "The clear button."
  attr(:combobox_id, :string, required: true)
  attr(:visible, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["aria-label", "data-slot"])

  def combobox_clear(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "combobox-clear"}
      type="button"
      data-size="icon-xs"
      aria-label={@rest[:"aria-label"] || "Clear selection"}
      disabled={@disabled}
      data-visible={if(@visible, do: "")}
      hidden={not @visible}
      phx-mounted={Combobox.owned_attributes(:clear)}
      class={[combobox_clear_button_class(), @class]}
      {Map.drop(@rest, [:"data-slot", :"aria-label"])}
    >
      <LiveShadcn.Icon.icon name="x" class={fact("jsx/ComboboxClear/class/1")} />
    </button>
    """
  end

  @doc "The floating Combobox content."
  attr(:combobox_id, :string, required: true)
  attr(:combobox, :map, default: nil)
  attr(:anchor, :string, default: nil)
  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:side_offset, :integer, default: 6)
  attr(:align_offset, :integer, default: 0)

  attr(:input_in_popup, :boolean,
    default: false,
    doc: "Sets the pinned dialog role for a popup-owned input."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["dir", "data-lang", "data-slot"])
  slot(:inner_block)

  def combobox_content(assigns) do
    assigns = assign(assigns, :combobox, assigns.combobox || default_combobox_config(assigns))
    anchor = assigns.anchor || base_ui_input_id()
    assigns = assign(assigns, :anchor_id, anchor)

    ~H"""
    <.portal id={"#{@combobox.id}-portal"} target="body" class="contents">
      <div
        id={"#{@combobox.id}-positioner"}
        data-combobox-controller={@combobox.id}
        hidden
        phx-hook={Popover.hook()}
        data-lb-anchor={@anchor_id}
        data-lb-side={@side}
        data-lb-align={@align}
        data-lb-offset={@side_offset}
        data-lb-align-offset={@align_offset}
        data-closed
        phx-mounted={Popover.owned_attributes(:positioner)}
        class={fact("jsx/ComboboxContent/class/0")}
      >
        <div
          id={base_ui_popup_id()}
          data-slot={@rest[:"data-slot"] || "combobox-content"}
          data-combobox-controller={@combobox.id}
          role={if(@input_in_popup, do: "dialog", else: "presentation")}
          hidden
          data-lb-popup
          data-closed
          phx-mounted={Popover.owned_attributes(:popup)}
          data-chips={to_string(not is_nil(@anchor))}
          class={LiveShadcn.Cn.merge([fact("jsx/ComboboxContent/class/1"), @class])}
          dir={@rest[:dir]}
          data-lang={@rest[:"data-lang"]}
          {Map.drop(@rest, [:"data-slot", :dir, :"data-lang"])}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </.portal>
    """
  end

  @doc "The listbox that owns Combobox items."
  attr(:combobox_id, :string, required: true)
  attr(:multiple, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_list(assigns) do
    ~H"""
    <div
      id={base_ui_list_id()}
      data-slot={@rest[:"data-slot"] || "combobox-list"}
      role="listbox"
      aria-orientation="vertical"
      aria-multiselectable={if(@multiple, do: "true")}
      class={[fact("jsx/ComboboxList/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A selectable Combobox item. Values must be stable strings."
  attr(:combobox_id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:selected, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_item(assigns) do
    assigns = assign(assigns, :item_id, "#{assigns.combobox_id}-item-#{safe_id(assigns.value)}")

    ~H"""
    <div
      id={@item_id}
      data-slot={@rest[:"data-slot"] || "combobox-item"}
      role="option"
      aria-selected={to_string(@selected)}
      data-selected={flag(@selected)}
      data-disabled={flag(@disabled)}
      data-value={@value}
      data-combobox-label={@label}
      phx-mounted={Combobox.owned_attributes(:item)}
      class={[fact("jsx/ComboboxItem/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
      <span :if={@selected} aria-hidden="true" class={fact("jsx/ComboboxItem/class/1")}>
        <LiveShadcn.Icon.icon name="check" class={fact("jsx/ComboboxItem/class/2")} />
      </span>
    </div>
    """
  end

  @doc "A labelled item group."
  attr(:combobox_id, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_group(assigns) do
    label_id =
      if assigns.label, do: "#{assigns.combobox_id}-group-#{safe_id(assigns.label)}-label"

    assigns = assign(assigns, :label_id, label_id)

    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "combobox-group"}
      role="group"
      aria-labelledby={@label_id}
      class={[fact("jsx/ComboboxGroup/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <.combobox_label :if={@label} id={@label_id}>{@label}</.combobox_label>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A group label."
  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_label(assigns) do
    ~H"""
    <div id={@id} data-slot={@rest[:"data-slot"] || "combobox-label"} class={[fact("jsx/ComboboxLabel/class/0"), @class]} {Map.drop(@rest, [:"data-slot"])}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Renders Combobox group items without adding a DOM part."
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_collection(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  @doc "The empty filtered-list message."
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_empty(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "combobox-empty"}
      role="status"
      aria-live="polite"
      aria-atomic="true"
      class={[fact("jsx/ComboboxEmpty/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A separator between visible groups."
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])

  def combobox_separator(assigns) do
    ~H"""
    <div data-slot={@rest[:"data-slot"] || "combobox-separator"} role="presentation" class={[fact("jsx/ComboboxSeparator/class/0"), @class]} {Map.drop(@rest, [:"data-slot"])} />
    """
  end

  @doc "The multiple-selection chip container."
  attr(:combobox, :map, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_chips(assigns) do
    assigns = assign(assigns, :combobox, assigns.combobox)

    ~H"""
    <div
      id={@rest[:id] || @combobox && "#{@combobox.id}-chips"}
      data-slot={@rest[:"data-slot"] || "combobox-chips"}
      role="toolbar"
      data-lb-combobox={if(@combobox, do: "")}
      data-combobox-controller={@combobox && @combobox.id}
      data-combobox-value={@combobox && Enum.join(@combobox.values, <<31>>)}
      data-combobox-has-value={@combobox && if(@combobox.has_value, do: "")}
      data-combobox-multiple={@combobox && if(@combobox.multiple, do: "")}
      data-combobox-auto-highlight={@combobox && if(@combobox.auto_highlight, do: "")}
      data-disabled={@combobox && flag(@combobox.disabled)}
      data-readonly={@combobox && flag(@combobox.readonly)}
      data-required={@combobox && flag(@combobox.required)}
      data-valid={if(@combobox, do: "")}
      phx-hook={@combobox && Combobox.hook()}
      phx-mounted={@combobox && Combobox.owned_attributes(:root)}
      class={[fact("jsx/ComboboxChips/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot", :id])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "One multiple-selection chip."
  attr(:value, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def combobox_chip(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "combobox-chip"}
      data-combobox-chip={@value}
      phx-mounted={Combobox.owned_attributes(:chip)}
      class={[fact("jsx/ComboboxChip/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
      <button
        type="button"
        data-slot="combobox-chip-remove"
        aria-disabled="false"
        phx-mounted={Combobox.owned_attributes(:chip_remove)}
        class={chip_remove_class()}
      >
        <LiveShadcn.Icon.icon name="x" class={fact("jsx/ComboboxChip/class/2")} />
      </button>
    </div>
    """
  end

  @doc "The editable input in a chips container."
  attr(:combobox_id, :string, required: true)
  attr(:combobox, :map, default: nil)
  attr(:id, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["aria-label", "aria-invalid", "autocomplete"])

  def combobox_chips_input(assigns) do
    assigns = assign(assigns, :combobox, assigns.combobox || default_combobox_config(assigns))
    assigns = assign(assigns, :id, assigns.id || base_ui_input_id())

    ~H"""
    <input
      id={@id}
      data-slot="combobox-chip-input"
      data-combobox-controller={@combobox.id}
      role="combobox"
      type="text"
      autocomplete={@rest[:autocomplete] || "off"}
      aria-autocomplete="list"
      aria-expanded="false"
      aria-haspopup="listbox"
      placeholder={@placeholder}
      disabled={@combobox.disabled || @disabled}
      data-disabled={flag(@combobox.disabled || @disabled)}
      phx-mounted={Combobox.owned_attributes(:input)}
      class={[fact("jsx/ComboboxChipsInput/class/0"), @class]}
      {Map.drop(@rest, [:autocomplete])}
    />
    """
  end

  defp initial_values(nil, _multiple), do: []
  defp initial_values(values, true) when is_list(values), do: Enum.map(values, &to_string/1)
  defp initial_values(value, true), do: [to_string(value)]

  defp initial_values(values, false) when is_list(values),
    do: values |> List.first() |> initial_values(false)

  defp initial_values(value, false), do: [to_string(value)]

  defp combobox_config(assigns, values) do
    %{
      id: assigns.id,
      name: assigns.name,
      form: assigns.form,
      values: values,
      has_value: not is_nil(assigns.value || assigns.default_value),
      multiple: assigns.multiple,
      auto_highlight: assigns.auto_highlight,
      disabled: assigns.disabled,
      readonly: assigns.readonly,
      required: assigns.required
    }
  end

  defp default_combobox_config(assigns) do
    %{
      id: assigns.combobox_id,
      name: nil,
      form: nil,
      values: [],
      has_value: false,
      multiple: false,
      auto_highlight: false,
      disabled: Map.get(assigns, :disabled, false),
      readonly: false,
      required: false
    }
  end

  defp safe_id(value), do: value |> to_string() |> String.replace(~r/[^a-zA-Z0-9_-]/, "-")

  # Base UI assigns these identities from its first Combobox instance. Each
  # official example mounts one instance, so the pinned runtime uses this shape.
  defp base_ui_input_id, do: "base-ui-_r_0_"
  defp base_ui_popup_input_id, do: "base-ui-_r_4_"
  defp base_ui_popup_id, do: "base-ui-_r_0_-popup"
  defp base_ui_list_id, do: "_r_1_"

  defp hidden_input_style(true),
    do:
      "clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0; padding: 0; width: 1px; height: 1px; margin: -1px; position: absolute;"

  defp hidden_input_style(false),
    do:
      "clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0; padding: 0; width: 1px; height: 1px; margin: -1px; position: fixed; top: 0; left: 0;"

  defp flag(true), do: ""
  defp flag(_), do: nil
end

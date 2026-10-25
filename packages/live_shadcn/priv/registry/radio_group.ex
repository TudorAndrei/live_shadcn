defmodule LiveShadcn.UI.RadioGroup do
  @moduledoc """
  Radio group.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/RadioGroup/class/0" => "cn-radio-group w-full",
    "jsx/RadioGroupItem/class/0" =>
      "cn-radio-group-item group/radio-group-item peer relative aspect-square shrink-0 border outline-none after:absolute after:-inset-x-3 after:-inset-y-2 disabled:cursor-not-allowed disabled:opacity-50",
    "jsx/RadioGroupItem/class/1" => "cn-radio-group-indicator",
    "jsx/RadioGroupItem/class/2" => "cn-radio-group-indicator-icon"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.FormControl

  @doc "The `radio-group` part."

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def radio_group(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot={@rest[:"data-slot"] || "radio-group"}
      role="radiogroup"
      phx-hook={LiveBase.RadioGroup.hook()}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/RadioGroup/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Represents one radio button in a group.

      <.radio_group_item group="updates" field={@form[:updates]} value="all"
        aria-label="All updates" />

  The visible control and the native form input are two elements. Selecting
  the control updates both elements before the form receives its change event.
  Items can share a field. The item whose value matches the field is checked.
  An explicit checked input takes priority over the field value.

  Give the visible control an accessible name through aria-label or a relation
  to an existing label:

      <.label id="all-updates-label">All updates</.label>
      <.radio_group_item group="updates" value="all"
        aria-labelledby="all-updates-label" />
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in identity, checked state and errors."
  )

  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :string, default: "true", doc: "What the form submits when the control is on.")
  attr(:checked, :boolean, default: nil)
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:indeterminate, :boolean, default: false)
  attr(:group, :string, required: true, doc: "The id of the group this radio belongs to.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def radio_group_item(assigns) do
    assigns = FormControl.from_radio(assigns)
    assigns = assign(assigns, :control_id, if(assigns.id, do: "#{assigns.id}-control"))

    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "radio-group-item"}
      role="radio"
      tabindex="0"
      id={@control_id}
      data-lb-radio-state={to_string(@checked)}
      aria-checked={to_string(@checked)}
      aria-label={rest_attribute(@rest, :"aria-label")}
      aria-labelledby={
        rest_attribute(@rest, :"aria-labelledby") ||
          if(@id && !rest_attribute(@rest, :"aria-label"), do: "#{@id}-label")
      }
      aria-disabled={if(@disabled, do: "true")}
      phx-click={
        if(@disabled or @readonly,
          do: nil,
          else: FormControl.select(control: @control_id, group: @group, input: @id)
        )
      }
      phx-mounted={FormControl.owned_attributes()}
      phx-keydown={
        if(@disabled or @readonly,
          do: nil,
          else: FormControl.select(control: @control_id, group: @group, input: @id)
        )
      }
      phx-key=" "
      data-checked={flag(@checked)}
      data-unchecked={flag(not @checked)}
      data-disabled={flag(@disabled)}
      data-readonly={flag(@readonly)}
      data-required={flag(@required)}
      data-valid={flag(@errors == [])}
      data-invalid={flag(@errors != [])}
      data-filled={flag(@checked)}
      class={[
        upstream_fact("jsx/RadioGroupItem/class/0"),
        (@class || "")
      ]}
      {
        Map.drop(@rest, [
          :"data-slot", "data-slot", :"aria-label", "aria-label",
          :"aria-labelledby", "aria-labelledby"
        ])
      }
    >
      <span hidden={not @checked} data-slot="radio-group-indicator" class={upstream_fact("jsx/RadioGroupItem/class/1")}>
        <span class={upstream_fact("jsx/RadioGroupItem/class/2")} />
      </span>
      {render_slot(@inner_block)}
    </span>
    <input
      type="radio"
      id={@id}
      name={@name || @group}
      value={@value}
      checked={@checked}
      disabled={@disabled}
      required={@required}
      tabindex="-1"
      aria-hidden="true"
      style="clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0; padding: 0; width: 1px; height: 1px; margin: -1px; position: absolute;"
    />
    """
  end

  defp rest_attribute(rest, name), do: rest[name] || rest[Atom.to_string(name)]

  defp flag(true), do: ""
  defp flag(_state), do: nil
end

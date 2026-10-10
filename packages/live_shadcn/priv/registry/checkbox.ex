defmodule LiveShadcn.UI.Checkbox do
  @moduledoc """
  Checkbox. Represents the checkbox itself.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Checkbox/class/0" =>
      "cn-checkbox peer relative shrink-0 outline-none after:absolute after:-inset-x-3 after:-inset-y-2 disabled:cursor-not-allowed disabled:opacity-50",
    "jsx/Checkbox/class/1" =>
      "cn-checkbox-indicator grid place-content-center text-current transition-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.FormControl

  @doc """
  Represents the checkbox itself.

      <.checkbox field={@form[:subscribe]} />

  The control a reader sees and the input a form submits are two elements,
  as Base UI documents. Flipping one flips the other, on the client, so a
  click costs no round trip and `phx-change` still fires.

  It needs an accessible name, and a `<label for>` cannot give it one: a
  label names a labelable element, and this is not one. Name it directly:

      <.label id="subscribe-label">Send me the pull requests</.label>
      <.checkbox field={@form[:subscribe]} aria-labelledby="subscribe-label" />
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
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

  attr(:on_toggle, :any,
    default: nil,
    doc: "An optional event name or JS command run after the client toggles."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def checkbox(assigns) do
    assigns = FormControl.from_checkable(assigns)
    assigns = assign(assigns, :control_id, if(assigns.id, do: "#{assigns.id}-control"))

    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "checkbox"}
      role="checkbox"
      tabindex="0"
      id={@control_id}
      data-lb-checkable-state={"#{@checked}:#{@indeterminate}"}
      aria-checked={if(@indeterminate, do: "mixed", else: to_string(@checked))}
      aria-label={rest_attribute(@rest, :"aria-label")}
      aria-labelledby={
        rest_attribute(@rest, :"aria-labelledby") ||
          if(@id && !rest_attribute(@rest, :"aria-label"), do: "#{@id}-label")
      }
      aria-disabled={if(@disabled, do: "true")}
      phx-click={
        if(@disabled or @readonly,
          do: nil,
          else: toggle(@control_id, @id, @on_toggle)
        )
      }
      phx-mounted={FormControl.owned_attributes()}
      phx-keydown={
        if(@disabled or @readonly,
          do: nil,
          else: toggle(@control_id, @id, @on_toggle)
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
      data-indeterminate={flag(@indeterminate)}
      class={[
        upstream_fact("jsx/Checkbox/class/0"),
        (@class || "")
      ]}
      {
        Map.drop(@rest, [
          :"data-slot",
          "data-slot",
          :"aria-label",
          "aria-label",
          :"aria-labelledby",
          "aria-labelledby"
        ])
      }
    >
      <span
        hidden={not (@checked or @indeterminate)}
        data-slot="checkbox-indicator"
        class={upstream_fact("jsx/Checkbox/class/1")}
      >
        <LiveShadcn.Icon.icon name="check" />
      </span>
      {render_slot(@inner_block)}
    </span>
    <input
      type="checkbox"
      data-lb-checkbox-input=""
      id={@id}
      name={@name}
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

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp toggle(control, input, on_toggle) do
    js = FormControl.toggle(control: control, input: input)

    cond do
      is_binary(on_toggle) -> Phoenix.LiveView.JS.push(js, on_toggle)
      is_struct(on_toggle, Phoenix.LiveView.JS) -> Phoenix.LiveView.JS.concat(js, on_toggle)
      true -> js
    end
  end

  defp rest_attribute(rest, attribute) do
    Map.get(rest, attribute) || Map.get(rest, Atom.to_string(attribute))
  end
end

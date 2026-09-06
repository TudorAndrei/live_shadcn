defmodule LiveShadcn.UI.Command do
  @moduledoc """
  Command.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveBase.Command

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Command/class/0" => "cn-command flex size-full flex-col overflow-hidden",
    "jsx/CommandDialog/class/0" => "sr-only",
    "jsx/CommandDialog/class/1" => "cn-command-dialog top-1/3 translate-y-0 overflow-hidden p-0",
    "jsx/CommandEmpty/class/0" => "cn-command-empty",
    "jsx/CommandGroup/class/0" => "cn-command-group",
    "jsx/CommandInput/class/0" => "cn-command-input-wrapper",
    "jsx/CommandInput/class/1" => "cn-command-input-group",
    "jsx/CommandInput/class/2" =>
      "cn-command-input outline-hidden disabled:cursor-not-allowed disabled:opacity-50",
    "jsx/CommandInput/class/3" => "cn-command-input-icon",
    "jsx/CommandItem/class/0" =>
      "cn-command-item group/command-item data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/CommandItem/class/1" =>
      "cn-command-item-indicator ml-auto opacity-0 group-has-data-[slot=command-shortcut]/command-item:hidden group-data-[checked=true]/command-item:opacity-100",
    "jsx/CommandList/class/0" => "cn-command-list overflow-x-hidden overflow-y-auto",
    "jsx/CommandSeparator/class/0" => "cn-command-separator",
    "jsx/CommandShortcut/class/0" => "cn-command-shortcut"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `command` part."

  attr(:id, :string, required: true, doc: "The stable id for the command state.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot={@rest[:"data-slot"] || "command"}
      tabindex="-1"
      phx-hook={Command.hook()}
      class={[upstream_fact("jsx/Command/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A Command menu in the shared Dialog component."

  attr(:id, :string, required: true, doc: "The stable id for the dialog state.")
  attr(:open, :boolean, default: false, doc: "Whether the dialog starts open.")
  attr(:title, :string, default: "Command Palette", doc: "The accessible dialog title.")

  attr(:description, :string,
    default: "Search for a command to run...",
    doc: "The accessible dialog description."
  )

  attr(:class, :any, default: nil, doc: "Appended to the dialog popup class string.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def command_dialog(assigns) do
    ~H"""
    <LiveShadcn.UI.Dialog.dialog
      id={@id}
      open={@open}
      show_trigger={false}
      show_close_button={false}
      header_outside_content
      header_class={upstream_fact("jsx/CommandDialog/class/0")}
      class={[upstream_fact("jsx/CommandDialog/class/1"), @class]}
      {@rest}
    >
      <:title>{@title}</:title>
      <:description>{@description}</:description>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Dialog.dialog>
    """
  end

  @doc "The `command-input-wrapper` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:controls, :string, default: nil, doc: "The id of the command list this input controls.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "type",
      "name",
      "value",
      "placeholder",
      "checked",
      "min",
      "max",
      "step",
      "minlength",
      "maxlength",
      "pattern",
      "readonly",
      "multiple",
      "autocomplete",
      "autocorrect",
      "spellcheck",
      "disabled",
      "required"
    ]
  )

  slot(:inner_block)

  def command_input(assigns) do
    ~H"""
    <div data-slot="command-input-wrapper" class={upstream_fact("jsx/CommandInput/class/0")}>
      <LiveShadcn.UI.InputGroup.input_group class={upstream_fact("jsx/CommandInput/class/1")}>
        <input
          data-slot={@rest[:"data-slot"] || "command-input"}
          role="combobox"
          type={@rest[:type] || "text"}
          autocomplete={@rest[:autocomplete] || "off"}
          autocorrect={@rest[:autocorrect] || "off"}
          spellcheck={@rest[:spellcheck] || "false"}
          aria-autocomplete="list"
          aria-expanded="true"
          aria-controls={@controls}
          class={[
            upstream_fact("jsx/CommandInput/class/2"),
            @class
          ]}
          {Map.drop(@rest, [:"data-slot", :type, :autocomplete, :autocorrect, :spellcheck])}
        />
        <LiveShadcn.UI.InputGroup.input_group_addon>
          <LiveShadcn.Icon.icon name="search" class={upstream_fact("jsx/CommandInput/class/3")} />
        </LiveShadcn.UI.InputGroup.input_group_addon>
      </LiveShadcn.UI.InputGroup.input_group>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `command-list` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:label, :string, default: "Suggestions", doc: "The accessible name of the command list.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_list(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-list"}
      role="listbox"
      aria-label={@label}
      tabindex="-1"
      class={[upstream_fact("jsx/CommandList/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div cmdk-list-sizer="">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc "The `command-empty` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_empty(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-empty"}
      role="presentation"
      hidden
      class={[upstream_fact("jsx/CommandEmpty/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `command-group` part."

  attr(:heading, :string, default: nil, doc: "The visible group heading.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-group"}
      role="presentation"
      class={[upstream_fact("jsx/CommandGroup/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div :if={@heading} cmdk-group-heading="" aria-hidden="true">{@heading}</div>
      <div cmdk-group-items="" role="group" aria-label={@heading}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `command-item` part."

  attr(:disabled, :boolean, default: false, doc: "Whether the item refuses selection.")
  attr(:value, :string, default: nil, doc: "The value used for filtering.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-item"}
      role="option"
      aria-disabled={to_string(@disabled)}
      aria-selected={to_string(@rest[:"data-selected"] == "true")}
      data-disabled={if(@disabled, do: "true")}
      data-value={@value}
      class={[
        upstream_fact("jsx/CommandItem/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot", :"data-selected"])}
    >
      {render_slot(@inner_block)}<LiveShadcn.Icon.icon
        name="check"
        class={upstream_fact("jsx/CommandItem/class/1")}
      />
    </div>
    """
  end

  @doc "The `command-shortcut` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_shortcut(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "command-shortcut"}
      class={[upstream_fact("jsx/CommandShortcut/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `command-separator` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_separator(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-separator"}
      role="separator"
      class={[upstream_fact("jsx/CommandSeparator/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end

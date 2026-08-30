defmodule LiveShadcn.UI.Command do
  @moduledoc """
  Command.

  Upstream exports 1 more part, each a thin
  wrapper around a part of `<.dialog>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Command/class/0" => "cn-command flex size-full flex-col overflow-hidden",
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

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command"}
      class={[upstream_fact("jsx/Command/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
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
          aria-expanded="true"
          aria-controls={@controls}
          class={[
            upstream_fact("jsx/CommandInput/class/2"),
            (@class || "")
          ]}
          {Map.drop(@rest, [:"data-slot"])}
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
      class={[upstream_fact("jsx/CommandList/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
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
      class={[upstream_fact("jsx/CommandEmpty/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `command-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-group"}
      role="presentation"
      class={[upstream_fact("jsx/CommandGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `command-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def command_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "command-item"}
      role="option"
      aria-disabled="false"
      aria-selected={to_string(@rest[:"data-selected"] == "true")}
      class={[
        upstream_fact("jsx/CommandItem/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
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
      class={[upstream_fact("jsx/CommandShortcut/class/0"), (@class || "")]}
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
      class={[upstream_fact("jsx/CommandSeparator/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end

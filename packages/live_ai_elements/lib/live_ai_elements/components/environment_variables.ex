defmodule LiveAiElements.Components.EnvironmentVariables do
  @moduledoc """
  Environment variables. Built on `shadcn/switch`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/EnvironmentVariable/class/0" => "flex items-center justify-between gap-4 px-4 py-3",
    "jsx/EnvironmentVariable/class/1" => "flex items-center gap-2",
    "jsx/EnvironmentVariableCopyButton/class/0" => "size-6 shrink-0",
    "jsx/EnvironmentVariableName/class/0" => "font-mono text-sm",
    "jsx/EnvironmentVariableRequired/class/0" => "text-xs",
    "jsx/EnvironmentVariableValue/class/0" => "font-mono text-muted-foreground text-sm",
    "jsx/EnvironmentVariableValue/class/1" => "select-none",
    "jsx/EnvironmentVariables/class/0" => "rounded-lg border bg-background",
    "jsx/EnvironmentVariablesContent/class/0" => "divide-y",
    "jsx/EnvironmentVariablesHeader/class/0" => "flex items-center justify-between border-b px-4 py-3",
    "jsx/EnvironmentVariablesTitle/class/0" => "font-medium text-sm",
    "jsx/EnvironmentVariablesToggle/class/1" => "text-muted-foreground text-xs",
    "jsx/Switch/class/0" => "cn-switch peer group/switch relative inline-flex items-center transition-all outline-none after:absolute after:-inset-x-3 after:-inset-y-2 data-disabled:cursor-not-allowed data-disabled:opacity-50",
    "jsx/Switch/class/1" => "cn-switch-thumb pointer-events-none block ring-0 transition-transform"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `environment_variables` part."
  attr(:default_show_values, :boolean, default: false)
  attr(:show_values, :boolean, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variables(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariables/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `environment_variables_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variables_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariablesHeader/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `environment_variables_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variables_title(assigns) do
    ~H"""
    <h3 class={[upstream_fact("jsx/EnvironmentVariablesTitle/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        Environment Variables
      <% end %>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc "The `environment_variables_toggle` part."
  attr(:show_values, :boolean, default: nil)
  attr(:size, :string, default: "default")

  attr(:on_toggle, :any,
    default: nil,
    doc:
      "Pushed when the switch is flipped. The server owns `show_values`, because the value it reveals is a secret."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variables_toggle(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariable/class/1"), (@class || "")]}>
      <span class={upstream_fact("jsx/EnvironmentVariablesToggle/class/1")}>
        <LiveShadcn.Icon.icon :if={@show_values} name="eye" width="14" height="14" />
        <LiveShadcn.Icon.icon :if={!@show_values} name="eye-off" width="14" height="14" />
      </span>
      <span
        role="switch"
        tabindex="0"
        aria-checked={to_string(@show_values == true)}
        phx-click={@on_toggle}
        phx-keydown={@on_toggle}
        phx-key=" "
        data-checked={if(@show_values == true, do: "")}
        data-unchecked={if(@show_values != true, do: "")}
        data-slot={@rest[:"data-slot"] || "switch"}
        data-size={@size}
        aria-label="Toggle value visibility"
        class={upstream_fact("jsx/Switch/class/0")}
        {Map.drop(@rest, [:"data-slot"])}
      >
        <span
          data-checked={if(@show_values == true, do: "")}
          data-unchecked={if(@show_values != true, do: "")}
          data-slot="switch-thumb"
          class={upstream_fact("jsx/Switch/class/1")}
        />
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  @doc "The `environment_variables_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variables_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariablesContent/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `environment_variable_group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variable_group(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariable/class/1"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `environment_variable_name` part."
  attr(:name, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variable_name(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/EnvironmentVariableName/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@name}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `environment_variable_value` part."
  attr(:display_value, :string, default: nil)
  attr(:show_values, :boolean, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variable_value(assigns) do
    ~H"""
    <span
      class={[
        upstream_fact("jsx/EnvironmentVariableValue/class/0"),
        if(!@show_values, do: upstream_fact("jsx/EnvironmentVariableValue/class/1"), else: nil),
        @class
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@display_value}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `environment_variable` part."
  attr(:name, :string, default: nil)
  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variable(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/EnvironmentVariable/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <div class={upstream_fact("jsx/EnvironmentVariable/class/1")}>
          <.environment_variable_name name={@name} />
        </div>
        <.environment_variable_value />
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `environment_variable_copy_button` part."
  attr(:copy_format, :string, default: "value", values: ["name", "value", "export"])
  attr(:size, :string, default: "icon")
  attr(:timeout, :any, default: 2000)
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:name, :string, required: true, doc: "The variable's name.")
  attr(:value, :string, required: true, doc: "The variable's value.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def environment_variable_copy_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={
        Map.get(%{"name" => @name, "export" => "export #{@name}=\"#{@value}\""}, @copy_format, @value)
      }
      data-lb-timeout={@timeout}
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/EnvironmentVariableCopyButton/class/0"), @class]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon data-lb-state="copied" hidden name="check" width="12" height="12" />
        <LiveShadcn.Icon.icon data-lb-state="idle" name="copy" width="12" height="12" />
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `environment_variable_required` part."
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def environment_variable_required(assigns) do
    ~H"""
    <LiveShadcn.UI.Badge.badge variant={@variant} class={[upstream_fact("jsx/EnvironmentVariableRequired/class/0"), @class]} {@rest}>
      <%= if @inner_block == [] do %>
        Required
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Badge.badge>
    """
  end
end

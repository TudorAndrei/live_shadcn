defmodule LiveAiElements.Components.SchemaDisplay do
  @moduledoc """
  Schema display.

  Upstream exports 3 more parts, each a thin
  wrapper around a part of `<.collapsible>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/SchemaDisplay/class/0" => "overflow-hidden rounded-lg border bg-background",
    "jsx/SchemaDisplay/class/1" => "flex items-center gap-3",
    "jsx/SchemaDisplayBody/class/0" => "divide-y",
    "jsx/SchemaDisplayDescription/class/0" => "border-b px-4 py-3 text-muted-foreground text-sm",
    "jsx/SchemaDisplayExample/class/0" =>
      "mx-4 mb-4 overflow-auto rounded-md bg-muted p-4 font-mono text-sm",
    "jsx/SchemaDisplayHeader/class/0" => "flex items-center gap-3 border-b px-4 py-3",
    "jsx/SchemaDisplayMethod/class/0" => "font-mono text-xs",
    "jsx/SchemaDisplayParameter/class/0" => "px-4 py-3 pl-10",
    "jsx/SchemaDisplayParameter/class/1" => "flex items-center gap-2",
    "jsx/SchemaDisplayParameter/class/2" => "font-mono text-sm",
    "jsx/SchemaDisplayParameter/class/3" => "text-xs",
    "jsx/SchemaDisplayParameter/class/5" =>
      "bg-red-100 text-red-700 text-xs dark:bg-red-900/30 dark:text-red-400",
    "jsx/SchemaDisplayParameter/class/6" => "mt-1 text-muted-foreground text-sm",
    "jsx/SchemaDisplayProperty/class/13" => "mt-1 pl-6 text-muted-foreground text-sm",
    "jsx/SchemaDisplayProperty/class/7" => "py-3 pr-4",
    "jsx/SchemaDisplayProperty/class/9" => "size-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `schema_display_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SchemaDisplayHeader/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display_method` part."
  attr(:method, :string, default: nil)
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_method(assigns) do
    ~H"""
    <LiveShadcn.UI.Badge.badge
      variant={@variant}
      class={[
        upstream_fact("jsx/SchemaDisplayMethod/class/0"),
        if(@method == "DELETE",
          do: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
          else: nil
        ),
        if(@method == "GET",
          do: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
          else: nil
        ),
        if(@method == "PATCH",
          do: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
          else: nil
        ),
        if(@method == "POST",
          do: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
          else: nil
        ),
        if(@method == "PUT",
          do: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
          else: nil
        ),
        @class
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@method}
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Badge.badge>
    """
  end

  @doc "The `schema_display_path` part."
  attr(:highlighted_path, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_path(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/SchemaDisplayParameter/class/2"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@highlighted_path}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `schema_display_description` part."
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_description(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/SchemaDisplayDescription/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@description}
      <% end %>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `schema_display_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SchemaDisplayBody/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display_parameter` part."
  attr(:description, :string, default: nil)
  attr(:location, :string, default: nil, values: [nil, "path", "query", "header"])
  attr(:name, :string, default: nil)
  attr(:required, :boolean, default: nil)
  attr(:type, :string, default: nil)
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_parameter(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SchemaDisplayParameter/class/0"), (@class || "")]} {@rest}>
      <div class={upstream_fact("jsx/SchemaDisplayParameter/class/1")}>
        <span class={upstream_fact("jsx/SchemaDisplayParameter/class/2")}>
          {@name}
        </span>
        <LiveShadcn.UI.Badge.badge variant={@variant} class={upstream_fact("jsx/SchemaDisplayParameter/class/3")}>
          {@type}
        </LiveShadcn.UI.Badge.badge>
        <LiveShadcn.UI.Badge.badge :if={@location} variant={@variant} class={upstream_fact("jsx/SchemaDisplayParameter/class/3")}>
          {@location}
        </LiveShadcn.UI.Badge.badge>
        <LiveShadcn.UI.Badge.badge
          :if={@required}
          variant={@variant}
          class={upstream_fact("jsx/SchemaDisplayParameter/class/5")}
        >
          required
        </LiveShadcn.UI.Badge.badge>
      </div>
      <p :if={@description} class={upstream_fact("jsx/SchemaDisplayParameter/class/6")}>
        {@description}
      </p>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display_property` part."
  attr(:depth, :any, default: 0)
  attr(:description, :string, default: nil)
  attr(:items, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:padding_left, :string, default: nil)
  attr(:properties, :string, default: nil)
  attr(:required, :boolean, default: nil)
  attr(:type, :string, default: nil)
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_property(assigns) do
    ~H"""
    <div style={"padding-left: #{@padding_left}"} class={[upstream_fact("jsx/SchemaDisplayProperty/class/7"), (@class || "")]} {@rest}>
      <div class={upstream_fact("jsx/SchemaDisplayParameter/class/1")}>
        <span class={upstream_fact("jsx/SchemaDisplayProperty/class/9")} />
        <span class={upstream_fact("jsx/SchemaDisplayParameter/class/2")}>
          {@name}
        </span>
        <LiveShadcn.UI.Badge.badge variant={@variant} class={upstream_fact("jsx/SchemaDisplayParameter/class/3")}>
          {@type}
        </LiveShadcn.UI.Badge.badge>
        <LiveShadcn.UI.Badge.badge
          :if={@required}
          variant={@variant}
          class={upstream_fact("jsx/SchemaDisplayParameter/class/5")}
        >
          required
        </LiveShadcn.UI.Badge.badge>
      </div>
      <p :if={@description} class={upstream_fact("jsx/SchemaDisplayProperty/class/13")}>
        {@description}
      </p>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display` part."
  attr(:description, :string, default: nil)
  attr(:method, :string, default: nil)
  attr(:parameters, :any, default: nil)
  attr(:path, :string, default: nil)
  attr(:request_body, :any, default: nil)
  attr(:response_body, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SchemaDisplay/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <.schema_display_header>
          <div class={upstream_fact("jsx/SchemaDisplay/class/1")}>
            <.schema_display_method method={@method} />
            <.schema_display_path />
          </div>
        </.schema_display_header>
        <.schema_display_description :if={@description} description={@description} />
        <.schema_display_content></.schema_display_content>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display_body` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_body(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SchemaDisplayBody/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `schema_display_example` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def schema_display_example(assigns) do
    ~H"""
    <pre
      phx-no-format
      class={[upstream_fact("jsx/SchemaDisplayExample/class/0"), (@class || "")]}
      {@rest}
    >{render_slot(@inner_block)}</pre>
    """
  end
end

defmodule LiveAiElements.Components.Artifact do
  @moduledoc """
  Artifact.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Artifact/class/0" =>
      "flex flex-col overflow-hidden rounded-lg border bg-background shadow-sm",
    "jsx/ArtifactAction/class/0" => "size-8 p-0 text-muted-foreground hover:text-foreground",
    "jsx/ArtifactAction/class/1" => "size-4",
    "jsx/ArtifactAction/class/2" => "sr-only",
    "jsx/ArtifactActions/class/0" => "flex items-center gap-1",
    "jsx/ArtifactContent/class/0" => "flex-1 overflow-auto p-4",
    "jsx/ArtifactDescription/class/0" => "text-muted-foreground text-sm",
    "jsx/ArtifactHeader/class/0" =>
      "flex items-center justify-between border-b bg-muted/50 px-4 py-3",
    "jsx/ArtifactTitle/class/0" => "font-medium text-foreground text-sm"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `artifact` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/Artifact/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `artifact_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ArtifactHeader/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `artifact_close` part."
  attr(:size, :string, default: "sm")
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def artifact_close(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      type="button"
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/ArtifactAction/class/0"), @class]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="x" class={upstream_fact("jsx/ArtifactAction/class/1")} />
      <% end %>
      {render_slot(@inner_block)}
      <span class={upstream_fact("jsx/ArtifactAction/class/2")}>
        Close
      </span>
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `artifact_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact_title(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/ArtifactTitle/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `artifact_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact_description(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/ArtifactDescription/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `artifact_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ArtifactActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `artifact_action` part."
  attr(:button, :string, default: nil)
  attr(:icon, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:size, :string, default: "sm")
  attr(:tooltip, :string, default: nil)
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def artifact_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      type="button"
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/ArtifactAction/class/0"), @class]}
      {@rest}
    >
      <LiveShadcn.Icon.icon :if={@icon} name={@icon} class={upstream_fact("jsx/ArtifactAction/class/1")} />
      {render_slot(@inner_block)}
      <span class={upstream_fact("jsx/ArtifactAction/class/2")}>
        {@label || @tooltip}
      </span>
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `artifact_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def artifact_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/ArtifactContent/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end

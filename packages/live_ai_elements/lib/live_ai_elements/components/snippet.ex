defmodule LiveAiElements.Components.Snippet do
  @moduledoc """
  Snippet. Built on `shadcn/input`, `shadcn/input-group`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/inputGroupAddonVariants/base" =>
      "cn-input-group-addon flex cursor-text items-center justify-center select-none",
    "cva/inputGroupAddonVariants/default/align" => "inline-start",
    "cva/inputGroupAddonVariants/variant/align/block-end" =>
      "cn-input-group-addon-align-block-end order-last w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/block-start" =>
      "cn-input-group-addon-align-block-start order-first w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/inline-end" =>
      "cn-input-group-addon-align-inline-end order-last",
    "cva/inputGroupAddonVariants/variant/align/inline-start" =>
      "cn-input-group-addon-align-inline-start order-first",
    "cva/inputGroupButtonVariants/base" => "cn-input-group-button flex items-center shadow-none",
    "cva/inputGroupButtonVariants/variant/size/icon-sm" => "cn-input-group-button-size-icon-sm",
    "cva/inputGroupButtonVariants/variant/size/icon-xs" => "cn-input-group-button-size-icon-xs",
    "cva/inputGroupButtonVariants/variant/size/sm" => "cn-input-group-button-size-sm",
    "cva/inputGroupButtonVariants/variant/size/xs" => "cn-input-group-button-size-xs",
    "jsx/SnippetCopyButton/class/0" => "size-3.5",
    "port/class/0" =>
      "cn-input w-full min-w-0 outline-none file:inline-flex file:border-0 file:bg-transparent file:text-foreground placeholder:text-muted-foreground disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 cn-input-group-input flex-1 text-foreground",
    "port/class/1" =>
      "cn-input-group-text flex items-center [&_svg]:pointer-events-none pl-2 font-normal text-muted-foreground",
    "port/class/2" =>
      "group/input-group cn-input-group relative flex w-full min-w-0 items-center outline-none has-[>textarea]:h-auto font-mono"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                        [table, "variant", group, choice] <- [String.split(path, "/")],
                        reduce: %{} do
                      variants ->
                        put_in(
                          variants,
                          [
                            Access.key(table, %{}),
                            Access.key(group, %{}),
                            Access.key(choice, nil)
                          ],
                          value
                        )
                    end)

  @doc "The `snippet` part."
  attr(:code, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def snippet(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group"}
      role="group"
      class={[
        Shadcn.input_group_class(),
        "font-mono",
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `input-group-addon` part."
  attr(:align, :string,
    default: @upstream_facts["cva/inputGroupAddonVariants/default/align"],
    values:
      @variant_classes
      |> get_in(["inputGroupAddonVariants", "align"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def snippet_addon(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group-addon"}
      role="group"
      data-align={@align}
      class={[Shadcn.input_group_addon_class(@align), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `snippet_text` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def snippet_text(assigns) do
    ~H"""
    <span
      class={[Shadcn.input_group_text_class(), "pl-2 font-normal text-muted-foreground", (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `input-group-control` part."
  attr(:code, :string, default: nil)
  attr(:type, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

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

  def snippet_input(assigns) do
    ~H"""
    <input
      data-slot={@rest[:"data-slot"] || "input-group-control"}
      type={@type}
      readonly
      value={@code}
      class={[
        Shadcn.input_group_input_class(),
        "flex-1 text-foreground",
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    />
    """
  end

  @doc "The `snippet_copy_button` part."
  attr(:size, :string,
    default: "icon-sm",
    values:
      @variant_classes
      |> get_in(["inputGroupButtonVariants", "size"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:timeout, :any, default: 2000)
  attr(:type, :string, default: "button")
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:code, :string, required: true, doc: "The text the button copies.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def snippet_copy_button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={@code}
      data-lb-timeout={@timeout}
      type={@type}
      data-size={@size}
      aria-label="Copy"
      title="Copy"
      class={[Shadcn.input_group_button_class(@size, @variant), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon
          data-lb-state="copied"
          hidden
          name="check"
          width="14"
          height="14"
          class={upstream_fact("jsx/SnippetCopyButton/class/0")}
        />
        <LiveShadcn.Icon.icon
          data-lb-state="idle"
          name="copy"
          width="14"
          height="14"
          class={upstream_fact("jsx/SnippetCopyButton/class/0")}
        />
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end
end

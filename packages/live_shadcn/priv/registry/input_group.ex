defmodule LiveShadcn.UI.InputGroup do
  @moduledoc """
  Input group.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

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
    "cva/inputGroupButtonVariants/default/size" => "xs",
    "cva/inputGroupButtonVariants/variant/size/icon-sm" => "cn-input-group-button-size-icon-sm",
    "cva/inputGroupButtonVariants/variant/size/icon-xs" => "cn-input-group-button-size-icon-xs",
    "cva/inputGroupButtonVariants/variant/size/sm" => "cn-input-group-button-size-sm",
    "cva/inputGroupButtonVariants/variant/size/xs" => "cn-input-group-button-size-xs",
    "jsx/InputGroup/class/0" =>
      "group/input-group cn-input-group relative flex w-full min-w-0 items-center outline-none has-[>textarea]:h-auto",
    "jsx/InputGroupInput/class/0" => "cn-input-group-input flex-1",
    "jsx/InputGroupText/class/0" =>
      "cn-input-group-text flex items-center [&_svg]:pointer-events-none",
    "jsx/InputGroupTextarea/class/0" => "cn-input-group-textarea flex-1 resize-none"
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

  alias LiveBase.FormControl

  @doc "The `input-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def input_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group"}
      role="group"
      class={[
        upstream_fact("jsx/InputGroup/class/0"),
        @class
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

  def input_group_addon(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group-addon"}
      role="group"
      data-align={@align}
      class={[
        variant_class("inputGroupAddonVariants", "align", @align),
        upstream_fact("cva/inputGroupAddonVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `input_group_button` part."
  attr(:size, :string,
    default: @upstream_facts["cva/inputGroupButtonVariants/default/size"],
    values:
      @variant_classes
      |> get_in(["inputGroupButtonVariants", "size"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:type, :string, default: "button", values: ["button", "submit", "reset"])
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def input_group_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      type={@type}
      data-size={@size}
      variant={@variant}
      class={[
        variant_class("inputGroupButtonVariants", "size", @size),
        upstream_fact("cva/inputGroupButtonVariants/base"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `input_group_text` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def input_group_text(assigns) do
    ~H"""
    <span
      class={[upstream_fact("jsx/InputGroupText/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The `input-group-control` part.

      <.input_group_input field={@form[:email]} />

  A `:field` fills in the id, the name, the value, and the errors. Errors
  show only once the form has been used: an untouched form is not a form
  with mistakes in it.
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
  )

  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "The field's value.")
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
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

  def input_group_input(assigns) do
    assigns = FormControl.from_field(assigns)

    ~H"""
    <LiveShadcn.UI.Input.input
      data-slot={@rest[:"data-slot"] || "input-group-control"}
      id={@id}
      name={@name}
      value={@value}
      disabled={@disabled}
      readonly={@readonly}
      required={@required}
      class={[upstream_fact("jsx/InputGroupInput/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    />
    """
  end

  @doc """
  The `input-group-control` part.

      <.input_group_textarea field={@form[:email]} />

  A `:field` fills in the id, the name, the value, and the errors. Errors
  show only once the form has been used: an untouched form is not a form
  with mistakes in it.
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
  )

  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "The field's value.")
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "name",
      "placeholder",
      "rows",
      "cols",
      "readonly",
      "wrap",
      "disabled",
      "required"
    ]
  )

  slot(:inner_block)

  def input_group_textarea(assigns) do
    assigns = FormControl.from_field(assigns)

    ~H"""
    <LiveShadcn.UI.Textarea.textarea
      data-slot={@rest[:"data-slot"] || "input-group-control"}
      id={@id}
      name={@name}
      value={@value}
      disabled={@disabled}
      readonly={@readonly}
      required={@required}
      class={[upstream_fact("jsx/InputGroupTextarea/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Textarea.textarea>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end

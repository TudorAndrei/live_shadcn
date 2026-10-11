defmodule LiveShadcn.UI.InputOtp do
  @moduledoc """
  Input otp.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/InputOTP/class/0" => "cn-input-otp flex items-center has-disabled:opacity-50",
    "jsx/InputOTP/class/1" => "cn-input-otp-input disabled:cursor-not-allowed",
    "jsx/InputOTPGroup/class/0" => "cn-input-otp-group flex items-center",
    "jsx/InputOTPSeparator/class/0" => "cn-input-otp-separator flex items-center",
    "jsx/InputOTPSlot/class/0" =>
      "cn-input-otp-slot relative flex items-center justify-center data-[active=true]:z-10",
    "jsx/InputOTPSlot/class/1" =>
      "cn-input-otp-caret pointer-events-none absolute inset-0 flex items-center justify-center",
    "jsx/InputOTPSlot/class/2" => "cn-input-otp-caret-line"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.FormControl

  @doc """
  The `input-otp` part.

      <.input_otp field={@form[:email]} />

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
  attr(:maxlength, :any, default: nil)
  attr(:pattern, :string, default: nil)
  attr(:inputmode, :string, default: "numeric")
  attr(:autocomplete, :string, default: "one-time-code")

  attr(:push_password_manager_strategy, :string,
    default: "increase-width",
    values: ["increase-width", "experimental-no-flickering", "none"],
    doc: "Reserves room for a detected password manager badge when space is available."
  )

  attr(:container_class_name, :string, default: nil)
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
      "readonly",
      "multiple",
      "disabled",
      "required"
    ]
  )

  slot(:inner_block)

  def input_otp(assigns) do
    assigns = FormControl.from_field(assigns)

    ~H"""
    <div
      data-input-otp-container
      data-input-otp-password-manager-strategy={
        @push_password_manager_strategy != "increase-width" && @push_password_manager_strategy
      }
      translate="no"
      style="--root-height: 0px; position: relative; cursor: text; user-select: none; -webkit-user-select: none; pointer-events: none"
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/InputOTP/class/0"), @container_class_name])}
    >
      {render_slot(@inner_block)}
      <div style="position: absolute; inset: 0; pointer-events: none">
        <input
          data-slot={@rest[:"data-slot"] || "input-otp"}
          data-input-otp
          id={@id}
          name={@name}
          value={@value}
          disabled={@disabled}
          readonly={@readonly}
          required={@required}
          maxlength={@maxlength}
          pattern={@pattern}
          inputmode={@inputmode}
          autocomplete={@autocomplete}
          phx-mounted={FormControl.owned_attributes()}
          spellcheck={false}
          style="position: absolute; inset: 0; width: 100%; height: 100%; display: flex; text-align: left; opacity: 1; color: transparent; pointer-events: all; background: transparent; caret-color: transparent; border: 0 solid transparent; outline: 0 solid transparent; box-shadow: none; line-height: 1; letter-spacing: -.5em; font-size: var(--root-height, 16px); font-family: monospace; font-variant-numeric: tabular-nums"
          class={LiveShadcn.Cn.merge([upstream_fact("jsx/InputOTP/class/1"), @class])}
          {Map.drop(@rest, [:"data-slot"])}
        />
      </div>
    </div>
    """
  end

  @doc "The `input-otp-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def input_otp_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-otp-group"}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/InputOTPGroup/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `input-otp-slot` part."
  attr(:char, :string, default: nil)
  attr(:has_fake_caret, :boolean, default: false)
  attr(:index, :integer, required: true)
  attr(:is_active, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "aria-invalid"])

  def input_otp_slot(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-otp-slot"}
      data-input-otp-index={@index}
      data-active={to_string(@is_active)}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/InputOTPSlot/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {@char}
      <div
        :if={@has_fake_caret}
        class={upstream_fact("jsx/InputOTPSlot/class/1")}
      >
        <div class={upstream_fact("jsx/InputOTPSlot/class/2")} />
      </div>
    </div>
    """
  end

  @doc "The `input-otp-separator` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def input_otp_separator(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-otp-separator"}
      role="separator"
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/InputOTPSeparator/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.Icon.icon name="minus" />{render_slot(@inner_block)}
    </div>
    """
  end
end

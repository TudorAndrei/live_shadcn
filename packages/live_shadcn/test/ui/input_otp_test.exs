defmodule LiveShadcn.UI.InputOtpTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.InputOtp

  test "the root owns the container and native input classes and composes slots" do
    html =
      render_component(&InputOtp.input_otp/1, %{
        id: "verification-code",
        maxlength: 6,
        push_password_manager_strategy: "none",
        pattern: "^\\d+$",
        container_class_name: "max-w-48",
        class: "input-class",
        inner_block: [slot(:inner_block, "slots")]
      })

    document = Floki.parse_fragment!(html)
    [container] = Floki.find(document, "[data-input-otp-container]")
    [input] = Floki.find(document, "input[data-input-otp]")

    assert Floki.attribute([container], "class") == [
             "cn-input-otp flex items-center has-disabled:opacity-50 max-w-48"
           ]

    assert Floki.text([container]) =~ "slots"
    assert Floki.attribute([container], "data-input-otp-password-manager-strategy") == ["none"]

    assert Floki.attribute([input], "class") == [
             "cn-input-otp-input disabled:cursor-not-allowed input-class"
           ]

    assert Floki.attribute([input], "maxlength") == ["6"]
    assert Floki.attribute([input], "pattern") == ["^\\d+$"]
    assert Floki.attribute([input], "inputmode") == ["numeric"]
    assert Floki.attribute([input], "autocomplete") == ["one-time-code"]
  end

  test "a slot exposes its index and accepts the official invalid state" do
    html =
      render_component(&InputOtp.input_otp_slot/1, %{
        index: 2,
        char: "0",
        is_active: true,
        "aria-invalid": "true"
      })

    [slot] = Floki.find(Floki.parse_fragment!(html), "[data-slot='input-otp-slot']")

    assert Floki.attribute([slot], "data-input-otp-index") == ["2"]
    assert Floki.attribute([slot], "data-active") == ["true"]
    assert Floki.attribute([slot], "aria-invalid") == ["true"]
    assert Floki.text([slot]) |> String.trim() == "0"
  end

  test "a separator uses its recipe by default and replaces it with caller classes" do
    for {caller, classes} <- [
          {nil, "cn-input-otp-separator flex items-center"},
          {"mx-2", "mx-2"},
          {"", ""}
        ] do
      html = render_component(&InputOtp.input_otp_separator/1, %{class: caller})
      [separator] = Floki.find(Floki.parse_fragment!(html), "[data-slot='input-otp-separator']")
      assert Floki.attribute([separator], "class") == [classes]
      assert Floki.attribute([separator], "role") == ["separator"]
    end
  end

  defp slot(name, text) do
    %{__slot__: name, inner_block: fn _, _ -> text end}
  end
end

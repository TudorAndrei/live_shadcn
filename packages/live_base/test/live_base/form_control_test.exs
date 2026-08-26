defmodule LiveBase.FormControlTest do
  use ExUnit.Case, async: true

  alias LiveBase.FormControl

  defp ops(%Phoenix.LiveView.JS{ops: ops}), do: ops
  defp attrs(js, kind), do: for([^kind, %{attr: [name | _]}] <- ops(js), do: name)
  defp removals(js), do: for(["remove_attr", %{attr: name}] <- ops(js), do: name)

  describe "flipping a checkbox" do
    test "sets the three attributes Base UI documents, and the input a form submits" do
      js = FormControl.toggle(control: "subscribe")

      assert attrs(js, "toggle_attr") == [
               "aria-checked",
               "data-checked",
               "data-unchecked",
               "hidden",
               "data-filled",
               "checked"
             ]
    end

    # A toggle is pressed rather than checked, and it has no tick to show.
    test "a pressed control has no indicator to flip" do
      js = FormControl.toggle(control: "bold", state: :pressed)

      refute "hidden" in attrs(js, "toggle_attr")
    end

    # The tick is in the DOM and hidden rather than mounted with the state, so
    # a click that costs no round trip can still show it.
    test "shows the indicator, which is where the tick is" do
      js = FormControl.toggle(control: "subscribe")

      assert [["toggle_attr", %{to: "#subscribe [data-slot$='-indicator']"}]] =
               Enum.filter(ops(js), &match?(["toggle_attr", %{attr: ["hidden" | _]}], &1))
    end

    test "tells the form, so phx-change fires" do
      js = FormControl.toggle(control: "subscribe")

      assert [["dispatch", %{event: "change", to: "#subscribe-input"}]] =
               Enum.filter(ops(js), &(hd(&1) == "dispatch"))
    end

    test "a control with no input beside it flips only itself" do
      js = FormControl.toggle(control: "bold", state: :pressed, input: false)

      assert attrs(js, "toggle_attr") == ["aria-pressed", "data-pressed", "data-filled"]
      assert Enum.filter(ops(js), &(hd(&1) == "dispatch")) == []
    end

    test "a toggle says pressed, because a screen reader announces it differently" do
      js = FormControl.toggle(control: "bold", state: :pressed)

      assert "aria-pressed" in attrs(js, "toggle_attr")
      refute "aria-checked" in attrs(js, "toggle_attr")
    end

    test "whatever the reader does, the control is touched and changed" do
      js = FormControl.toggle(control: "subscribe")

      assert "data-dirty" in attrs(js, "set_attr")
      assert "data-touched" in attrs(js, "set_attr")
    end
  end

  describe "choosing a radio" do
    test "unchooses the others by role, not by a list of ids" do
      js = FormControl.select(control: "style-nova", group: "style")

      others = "#style [role='radio']:not(#style-nova)"

      assert Enum.any?(
               ops(js),
               &match?(["remove_attr", %{attr: "data-checked", to: ^others}], &1)
             )
    end

    test "clears the other inputs, so a form cannot submit two answers" do
      js = FormControl.select(control: "style-nova", group: "style")

      assert "checked" in removals(js)
    end

    test "checks the one that was chosen" do
      js = FormControl.select(control: "style-nova", group: "style")

      assert Enum.any?(
               ops(js),
               &match?(["set_attr", %{attr: ["checked", ""], to: "#style-nova-input"}], &1)
             )
    end
  end

  describe "what the client owns" do
    test "only the three the server cannot know" do
      assert [["ignore_attrs", %{attrs: attrs}]] = ops(FormControl.owned_attributes())

      assert attrs == ["data-dirty", "data-touched", "data-focused"]
    end

    test "the checked state is not among them, because the form owns it" do
      assert [["ignore_attrs", %{attrs: attrs}]] = ops(FormControl.owned_attributes())

      refute "data-checked" in attrs
      refute "data-invalid" in attrs
    end
  end

  describe "filling assigns in from a field" do
    defp field(value, errors \\ []) do
      %Phoenix.HTML.FormField{
        id: "user_subscribe",
        name: "user[subscribe]",
        field: :subscribe,
        form: %Phoenix.HTML.Form{name: "user", params: %{}},
        value: value,
        errors: errors
      }
    end

    defp assigns(field, overrides \\ %{}) do
      Map.merge(
        %{field: field, id: nil, name: nil, checked: nil, errors: [], __changed__: nil},
        overrides
      )
    end

    test "takes the id and the name the form already knows" do
      result = FormControl.from_checkable(assigns(field(true)))

      assert result.id == "user_subscribe"
      assert result.name == "user[subscribe]"
    end

    test "reads the checked state from what the field holds" do
      assert FormControl.from_checkable(assigns(field(true))).checked
      assert FormControl.from_checkable(assigns(field("on"))).checked
      refute FormControl.from_checkable(assigns(field(nil))).checked
    end

    test "what the caller set wins over what the field says" do
      result = FormControl.from_checkable(assigns(field(true), %{id: "mine", checked: false}))

      assert result.id == "mine"
      refute result.checked
    end

    test "an untouched form is not a form with mistakes in it" do
      # The field has an error, but nobody has typed anything yet.
      result = FormControl.from_checkable(assigns(field(nil, [{"can't be blank", []}])))

      assert result.errors == []
    end
  end
end

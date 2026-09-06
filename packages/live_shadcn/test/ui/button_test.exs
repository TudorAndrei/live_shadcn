defmodule LiveShadcn.UI.ButtonTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Button

  defp button(assigns \\ %{}) do
    assigns =
      Map.merge(
        %{inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> "Save" end}]},
        assigns
      )

    render_component(&Button.button/1, assigns)
  end

  describe "the variant table" do
    test "the default variant and size come from the cva defaults, not from a guess" do
      classes = classes(slot(button(), "button"))

      assert "cn-button-variant-default" in classes
      assert "cn-button-size-default" in classes
    end

    test "a named variant selects the class string upstream gave it" do
      classes = classes(slot(button(%{variant: "destructive"}), "button"))

      assert "cn-button-variant-destructive" in classes
      refute "cn-button-variant-default" in classes
    end

    test "size and variant are independent" do
      classes = classes(slot(button(%{variant: "ghost", size: "lg"}), "button"))

      assert "cn-button-variant-ghost" in classes
      assert "cn-button-size-lg" in classes
    end

    test "a variant nobody defined is refused at compile time, not rendered wrong" do
      # `values:` on the attr follows the upstream table, so LiveView reports
      # the mistake rather than emitting a class that does not exist.
      variant = Enum.find(Button.__components__()[:button][:attrs], &(&1.name == :variant))

      assert variant.opts[:values] ==
               ~w(default destructive ghost link outline secondary)

      assert variant.opts[:default] == "default"
    end
  end

  describe "the markup" do
    test "is a button carrying the base class string upstream wrote" do
      assert "cn-button" in classes(slot(button(), "button"))
      assert [_] = Floki.find(Floki.parse_fragment!(button()), "button[data-slot='button']")
    end

    test "the caller's class is appended, never replaced" do
      classes = classes(slot(button(%{class: "w-full"}), "button"))

      assert "cn-button" in classes
      assert "w-full" in classes
    end

    test "the public class helper styles another element from the same table" do
      classes = Button.button_class(variant: "secondary", size: "sm") |> String.split()

      assert "cn-button" in classes
      assert "cn-button-variant-secondary" in classes
      assert "cn-button-size-sm" in classes
    end

    test "can omit the base shrink token for a pinned style variant" do
      refute "shrink-0" in (Button.button_class(shrink: false) |> String.split())
      assert "shrink-0" in (Button.button_class() |> String.split())
    end

    test "holds its content" do
      assert button() =~ "Save"
    end
  end
end

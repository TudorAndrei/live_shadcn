defmodule LiveAiElements.ShadcnTest do
  use ExUnit.Case, async: true

  alias LiveAiElements.Shadcn

  test "button classes use the pinned AI Elements shadcn contract" do
    classes = Shadcn.button_class("icon-sm", "outline")

    assert classes =~ "rounded-md text-sm font-medium"
    assert classes =~ "border bg-background shadow-xs"
    assert classes =~ "size-8"
    refute classes =~ "cn-button"
  end

  test "button group classes keep the original child selectors" do
    classes = Shadcn.button_group_class("horizontal")

    assert classes =~ "[&>*:not(:first-child)]:rounded-l-none"
    assert classes =~ "[&>*:not(:first-child)]:border-l-0"
    assert classes =~ "[&>*:not(:last-child)]:rounded-r-none"
  end

  test "form controls use the pinned AI Elements shadcn contract" do
    assert Shadcn.input_class() =~ "selection:bg-primary"
    assert Shadcn.input_class() =~ "focus-visible:ring-[3px]"
    assert Shadcn.textarea_class() =~ "rounded-md border bg-transparent px-3 py-2"
  end
end

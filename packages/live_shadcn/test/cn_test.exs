defmodule LiveShadcn.CnTest do
  use ExUnit.Case, async: true

  alias LiveShadcn.Cn

  test "repeated custom classes survive known utility conflicts" do
    assert Cn.merge([
             "cn-menu-target w-(--anchor-width) cn-menu-translucent",
             "cn-menu-target cn-menu-translucent w-auto"
           ]) == "cn-menu-target cn-menu-translucent cn-menu-target cn-menu-translucent w-auto"
  end

  test "a later display class removes the earlier display class" do
    assert Cn.merge(["inline-flex items-center", "flex"]) == "items-center flex"
  end

  test "line clamp replaces flex display" do
    assert Cn.merge(["flex w-fit", "line-clamp-1"]) == "w-fit line-clamp-1"
  end

  test "a later flex keeps the earlier clamp overflow contract" do
    assert Cn.merge(["line-clamp-1 flex w-fit items-center"]) ==
             "line-clamp-1 flex w-fit items-center"
  end

  test "scoped line clamp stays with scoped flex" do
    assert Cn.merge([
             "*:data-[slot=select-value]:line-clamp-1",
             "*:data-[slot=select-value]:flex"
           ]) ==
             "*:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex"
  end

  test "a later flex value removes the earlier flex value" do
    assert Cn.merge(["flex flex-1 flex-col", "flex-none"]) == "flex flex-col flex-none"
  end

  test "a later justification removes the earlier justification" do
    assert Cn.merge(["items-center justify-center", "justify-start"]) ==
             "items-center justify-start"
  end

  test "nested Phoenix class lists are flattened" do
    assert Cn.merge(["inline-flex", ["flex", nil], false]) == "flex"
  end

  test "a later size token removes earlier width and height tokens" do
    assert Cn.merge(["h-9 w-5", "size-6"]) == "size-6"
  end

  test "a fixed width replaces an earlier arbitrary CSS-variable width" do
    assert Cn.merge(["w-(--anchor-width)", "w-60"]) == "w-60"
  end

  test "an arbitrary CSS-variable width replaces an earlier fixed width" do
    assert Cn.merge(["w-60", "w-(--anchor-width)"]) == "w-(--anchor-width)"
  end

  test "a width replacement keeps non-conflicting arbitrary classes" do
    assert Cn.merge(["w-(--anchor-width) max-w-(--available-width)", "w-60"]) ==
             "max-w-(--available-width) w-60"
  end

  test "a later height token keeps an earlier size token for width" do
    assert Cn.merge(["size-6", "h-9"]) == "size-6 h-9"
  end

  test "a later all-padding token removes earlier axis tokens" do
    assert Cn.merge(["px-4 py-2", "p-0"]) == "p-0"
  end

  test "a later horizontal-padding token keeps all-padding for the vertical axis" do
    assert Cn.merge(["p-0", "px-4"]) == "p-0 px-4"
  end

  test "a later radius token replaces the earlier radius token" do
    assert Cn.merge(["rounded-md", "rounded-full"]) == "rounded-full"
  end

  test "a later transition property replaces transition all" do
    assert Cn.merge(["transition-all", "transition-opacity"]) == "transition-opacity"
  end

  test "variant-prefixed conflicts stay separate from unprefixed conflicts" do
    assert Cn.merge(["size-6 hover:h-9", "h-8 hover:size-4"]) ==
             "size-6 h-8 hover:size-4"
  end

  test "a later variant background replaces an earlier background" do
    assert Cn.merge(["hover:bg-accent", "hover:bg-background"]) == "hover:bg-background"
  end
end

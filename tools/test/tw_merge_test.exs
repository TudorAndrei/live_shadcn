defmodule LiveShadcnTools.TwMergeTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.TwMerge

  # The two calls the calendar reader resolves. Both were checked against what
  # React renders in the browser, class for class and in order.
  @button_base "cn-button group/button inline-flex shrink-0 items-center justify-center " <>
                 "whitespace-nowrap transition-all outline-none select-none " <>
                 "disabled:pointer-events-none disabled:opacity-50 " <>
                 "[&_svg]:pointer-events-none [&_svg]:shrink-0"

  describe "a later class wins" do
    test "removes the earlier member of the same group" do
      assert TwMerge.merge(["inline-flex", "flex"]) == "flex"
      assert TwMerge.merge(["flex", "inline-flex"]) == "inline-flex"
    end

    test "keeps the later position, not the earlier one" do
      assert TwMerge.merge(["select-none p-0", "gap-1 select-none"]) == "p-0 gap-1 select-none"
    end

    test "leaves classes that set different things alone" do
      assert TwMerge.merge(["w-full", "h-4", "min-w-8"]) == "w-full h-4 min-w-8"
    end

    test "a variant is part of the group" do
      assert TwMerge.merge(["disabled:opacity-50", "aria-disabled:opacity-50"]) ==
               "disabled:opacity-50 aria-disabled:opacity-50"

      assert TwMerge.merge(["opacity-50", "opacity-100"]) == "opacity-100"
    end

    test "an arbitrary variant may hold a colon of its own" do
      assert TwMerge.merge(["[&:has(:checked)]:flex", "flex"]) == "[&:has(:checked)]:flex flex"
    end
  end

  describe "a class it does not recognise" do
    test "is its own group, so nothing is dropped on a guess" do
      assert TwMerge.merge(["text-sm", "text-muted-foreground"]) ==
               "text-sm text-muted-foreground"

      assert TwMerge.merge(["cn-button", "cn-calendar-day-button"]) ==
               "cn-button cn-calendar-day-button"
    end

    test "still drops an exact repeat" do
      assert TwMerge.merge(["rdp-day", "p-0", "rdp-day"]) == "p-0 rdp-day"
    end
  end

  describe "what the calendar reads" do
    test "the day button loses inline-flex to the flex the day button asks for" do
      merged =
        TwMerge.merge([
          @button_base,
          "cn-button-variant-ghost cn-button-size-icon",
          "cn-calendar-day-button relative isolate z-10 flex aspect-square size-auto w-full",
          "rdp-day",
          "rdp-day_button"
        ])

      refute String.contains?(merged, "inline-flex")
      assert String.contains?(merged, " flex ")
      assert String.ends_with?(merged, "rdp-day rdp-day_button")
    end

    test "the nav button keeps inline-flex, because nothing later asks for a display" do
      merged =
        TwMerge.merge([
          @button_base,
          "cn-button-variant-ghost cn-button-size-default",
          "size-(--cell-size) p-0 select-none aria-disabled:opacity-50",
          "rdp-button_previous"
        ])

      assert String.contains?(merged, "inline-flex")
      # Stated twice by upstream, kept once, at the position of the later one.
      assert merged =~ ~r/p-0 select-none aria-disabled:opacity-50 rdp-button_previous$/
    end
  end
end

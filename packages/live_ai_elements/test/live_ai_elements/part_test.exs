defmodule LiveAiElements.PartTest do
  use ExUnit.Case, async: true

  doctest LiveAiElements.Part

  alias LiveAiElements.Part

  describe "the status ladder" do
    test "moves up" do
      part = Part.new("a", :text)

      assert Part.update(part, %{status: :streaming}).status == :streaming
      assert Part.update(part, %{status: :complete}).status == :complete
    end

    test "never moves down" do
      part = Part.new("a", :tool_call, status: :running)

      assert Part.update(part, %{status: :pending}).status == :running
      assert Part.update(part, %{status: :streaming}).status == :running
    end

    test "stops at the first terminal rung it reaches" do
      for stopped <- [:complete, :incomplete, :error], next <- [:complete, :incomplete, :error] do
        part = Part.new("a", :text, status: stopped)

        assert Part.update(part, %{status: next}).status == stopped
      end
    end

    test "so the end of a turn cannot mark a finished part incomplete" do
      part = Part.new("a", :text, status: :complete)

      assert Part.update(part, %{status: :incomplete}) == part
    end
  end

  describe "update/2" do
    test "merges meta rather than replacing it" do
      part = Part.new("a", :tool_call, meta: %{tool: "search"})

      assert Part.update(part, %{meta: %{output: "found"}}).meta ==
               %{tool: "search", output: "found"}
    end

    test "replaces text, because the terminal event is the authoritative copy" do
      part = Part.new("a", :text, text: "half")

      assert Part.update(part, %{text: "the whole thing"}).text == "the whole thing"
    end

    test "returns the part it was given when nothing moved" do
      part = Part.new("a", :text, status: :streaming)

      assert Part.update(part, %{}) == part
      assert Part.update(part, %{status: :pending}) == part
    end
  end

  test "terminal?/1 is what the end of a turn asks" do
    refute Part.terminal?(Part.new("a", :text))
    refute Part.terminal?(Part.new("a", :text, status: :streaming))
    refute Part.terminal?(Part.new("a", :tool_call, status: :running))

    for status <- [:complete, :incomplete, :error] do
      assert Part.terminal?(Part.new("a", :text, status: status))
    end
  end
end

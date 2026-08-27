defmodule LiveShadcnTools.GenTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Gen
  alias LiveShadcnTools.Gen.Clipboard
  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational

  describe "recipes" do
    test "a spec whose recipe nobody has written is reported, not guessed at" do
      assert {:error, "nonesuch"} =
               Gen.module(%{"recipe" => "nonesuch"}, module: LiveShadcn.UI.Nothing)
    end

    test "every recipe named in the inventory either exists or is still to come" do
      inventory =
        Path.expand("../../registry/INVENTORY.json", __DIR__) |> File.read!() |> Jason.decode!()

      named = inventory["components"] |> Enum.map(& &1["recipe"]) |> Enum.uniq()

      for recipe <- Gen.recipes() do
        assert recipe in named, "the #{recipe} recipe is written but no component names it"
      end
    end
  end

  describe "a choice the client owns" do
    # `const Icon = isCopied ? CheckIcon : CopyIcon`. The server has no answer
    # to write — the browser holds it for two seconds — so both branches are
    # drawn and the hook shows one.
    defp choice do
      %{
        "type" => "choice",
        "when" => "isCopied",
        "then" => [%{"type" => "icon", "icons" => %{"lucide" => "CheckIcon"}}],
        "else" => [%{"type" => "icon", "icons" => %{"lucide" => "CopyIcon"}}]
      }
    end

    defp ctx(extra \\ %{}) do
      Map.merge(
        %{
          attrs: %{},
          children: "{render_slot(@inner_block)}",
          class: "@class",
          variants: %{},
          params: %{},
          contexts: [],
          client_attributes: [],
          hook_part: nil,
          rest: false
        },
        extra
      )
    end

    test "both branches are drawn, marked, and the one not started in is hidden" do
      source =
        Heex.render(choice(), ctx(%{client_state: %{"isCopied" => Clipboard.state()}}))

      assert source =~ ~s|data-lb-state="copied" hidden name="check"|
      assert source =~ ~s|data-lb-state="idle" name="copy"|
      refute source =~ ":if"
    end

    # The mechanism is something a recipe asks for. Every other choice in the
    # registry is the server's, and one that quietly became the client's would
    # draw two elements where upstream draws one.
    test "the same choice, undeclared, is still the server's decision" do
      assert_raise RuntimeError, ~r/isCopied/, fn ->
        Heex.render(choice(), ctx())
      end
    end
  end

  describe "presentational attributes" do
    test "local TypeScript annotations select Phoenix attribute types" do
      part = %{
        "params" => %{"enabled" => nil, "count" => nil, "side" => nil},
        "tree" => %{},
        "types" => %{
          "enabled" => %{"type" => "boolean", "optional" => true},
          "count" => %{"type" => "number", "optional" => false},
          "side" => %{"values" => ["left", "right"], "optional" => true}
        }
      }

      assert Presentational.attributes(part, %{"parts" => []}) == [
               %{name: "count", default: nil, values: nil, type: ":any"},
               %{name: "enabled", default: nil, values: nil, type: ":boolean"},
               %{name: "side", default: nil, values: ["left", "right"], type: ":string"}
             ]
    end
  end
end

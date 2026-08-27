defmodule LiveShadcnTools.GenTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Gen
  alias LiveShadcnTools.Gen.Clipboard
  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational

  @specs Path.expand("../../registry/spec", __DIR__)

  # Every spec here is a shadcn one. The directory is part of the path because
  # a name is not an identity: AI Elements has a `message` of its own.
  defp spec(name),
    do: @specs |> Path.join("shadcn/#{name}.json") |> File.read!() |> Jason.decode!()

  defp generated(name) do
    Path.expand("../../packages/live_shadcn/priv/registry/#{name}.ex", __DIR__)
  end

  describe "generation is deterministic" do
    # The whole pipeline rests on this. If the same spec can produce two
    # different files, `mix ui.gen --check` cannot tell a hand edit from a
    # reordering, `mix ui.sync` cannot tell an upstream change from noise, and a
    # sync pull request is a diff nobody can read.
    #
    # The trap that made this a test: atoms sort by when the VM first saw them,
    # not by their letters. A recipe that iterated a map keyed by atom produced
    # its attributes in a different order in a different run.
    test "the same spec produces the same bytes, twice" do
      for name <- ~w(accordion checkbox card alert badge) do
        spec = spec(name)
        module = Gen.module_name(LiveShadcn.UI, name)

        assert {:ok, first} = Gen.module(spec, module: module)
        assert {:ok, second} = Gen.module(spec, module: module)
        assert first == second, "#{name} generated two different files in one run"
      end
    end

    test "what is on disk is what the spec produces" do
      for name <- ~w(accordion checkbox card alert badge) do
        assert {:ok, source} =
                 Gen.module(spec(name), module: Gen.module_name(LiveShadcn.UI, name))

        assert source == File.read!(generated(name)),
               "#{name} on disk does not match its spec. Run `mix ui.gen`."
      end
    end
  end

  describe "a recipe that draws one component out of another's anatomy" do
    # `sonner` renders a stack whose parts are the toast's, because sonner
    # exposes only a manager and the server owns the list. The class string of
    # the element that holds the title and the description therefore belongs to
    # the toast, and this recipe used to hold a second, hand-maintained copy of
    # it.
    test "sonner reads the toast's text wrapper rather than holding a copy" do
      assert {:ok, source} =
               Gen.module(spec("sonner"),
                 module: LiveShadcn.UI.Sonner,
                 resolve: fn "shadcn", name -> spec(name) end
               )

      wrapper =
        spec("toast")
        |> Map.fetch!("parts")
        |> Enum.find(&(&1["name"] == "toaster"))
        |> get_in(["tree", "children"])
        |> find_class(~r/flex-col/)

      assert source =~ wrapper
    end

    test "and refuses to draw one at all when that anatomy is not on disk" do
      assert_raise RuntimeError, ~r/no toast spec is on disk/, fn ->
        Gen.module(spec("sonner"), module: LiveShadcn.UI.Sonner, resolve: fn _, _ -> nil end)
      end
    end
  end

  # The class of the first element below here that matches, found by walking
  # rather than by naming a string this test would then also be maintaining.
  defp find_class(nodes, pattern) when is_list(nodes),
    do: Enum.find_value(nodes, &find_class(&1, pattern))

  defp find_class(%{} = node, pattern) do
    if is_binary(node["class"]) and Regex.match?(pattern, node["class"]),
      do: node["class"],
      else: find_class(List.wrap(node["children"]), pattern)
  end

  defp find_class(_node, _pattern), do: nil

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

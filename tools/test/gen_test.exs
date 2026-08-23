defmodule LiveShadcnTools.GenTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Gen

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
      for name <- ~w(accordion button dialog checkbox card) do
        spec = spec(name)
        module = Gen.module_name(LiveShadcn.UI, name)

        assert {:ok, first} = Gen.module(spec, module: module)
        assert {:ok, second} = Gen.module(spec, module: module)
        assert first == second, "#{name} generated two different files in one run"
      end
    end

    test "what is on disk is what the spec produces" do
      for name <- ~w(accordion button dialog checkbox card) do
        assert {:ok, source} =
                 Gen.module(spec(name), module: Gen.module_name(LiveShadcn.UI, name))

        assert source == File.read!(generated(name)),
               "#{name} on disk does not match its spec. Run `mix ui.gen`."
      end
    end
  end

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
end

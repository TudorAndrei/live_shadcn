defmodule LiveShadcnTools.VerificationShardsTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.VerificationShards

  test "every source-qualified target belongs to exactly one balanced shard" do
    targets = for name <- ~w(large medium small tiny), do: {"shadcn", name}

    previews =
      Map.new(Enum.zip(~w(large medium small tiny), [9, 6, 4, 1]), fn {name, size} ->
        {name, Enum.to_list(1..size)}
      end)

    shards = VerificationShards.plan(targets, previews, 2)
    assigned = Enum.flat_map(shards, & &1["components"])

    assert Enum.sort(assigned) ==
             Enum.map(targets, fn {source, name} -> source <> "/" <> name end) |> Enum.sort()

    assert length(assigned) == length(Enum.uniq(assigned))
    assert Enum.map(shards, & &1["weight"]) == [42, 42]
    assert VerificationShards.plan(Enum.reverse(targets), previews, 2) == shards
  end

  test "documentation families and shared component names stay in the plan" do
    targets = [{"shadcn", "data-table"}, {"shadcn", "code-block"}, {"ai_elements", "code-block"}]

    previews = %{
      "data-table" => ["default"],
      "shadcn-code-block" => ["basic", "tabs"],
      "code-block" => ["default"]
    }

    shards = VerificationShards.plan(targets, previews, 2)

    assert Enum.sort(Enum.flat_map(shards, & &1["components"])) ==
             ~w(ai_elements/code-block shadcn/code-block shadcn/data-table)

    assert Enum.sum(Enum.map(shards, & &1["weight"])) == 17
  end

  test "shard selection rejects invalid or empty work before verification" do
    targets = [{"shadcn", "button"}, {"shadcn", "alert"}]
    assert VerificationShards.select(targets, %{}, "1/2") == [{"shadcn", "alert"}]

    for shard <- ["0/2", "3/2", "1/0", "one/two", "1/65", "3/4"] do
      assert_raise ArgumentError, fn -> VerificationShards.select(targets, %{}, shard) end
    end
  end

  test "interactive examples receive more work than static examples with the same count" do
    root = Path.join(System.tmp_dir!(), "shard-cost-#{System.unique_integer([:positive])}")
    directory = Path.join(root, "registry/snapshot")
    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf!(root) end)

    File.write!(
      Path.join(directory, "dialog-default.html"),
      ~s(<button aria-expanded="false">Open</button>)
    )

    File.write!(Path.join(directory, "alert-default.html"), "<div>Message</div>")
    previews = %{"dialog" => ["default"], "alert" => ["default"]}
    costs = VerificationShards.costs(previews, root)
    targets = [{"shadcn", "dialog"}, {"shadcn", "alert"}]
    shards = VerificationShards.plan(targets, previews, 2, costs)

    assert costs["dialog"] > costs["alert"]
    assert hd(shards)["components"] == ["shadcn/dialog"]
    assert VerificationShards.select(targets, previews, "1/2", costs) == [{"shadcn", "dialog"}]
  end

  test "measured component times balance groups and retain estimates for new components" do
    root = Path.join(System.tmp_dir!(), "shard-timing-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "registry"))
    on_exit(fn -> File.rm_rf!(root) end)

    File.write!(
      Path.join(root, "registry/VERIFICATION_TIMINGS.json"),
      Jason.encode!(%{
        "version" => 1,
        "milliseconds_per_weight_unit" => 1000,
        "components_ms" => %{
          "shadcn/alert" => 100_000,
          "shadcn/dialog" => 20_000,
          "ai_elements/alert" => 10_000
        }
      })
    )

    previews = Map.new(~w(alert dialog fresh), &{&1, ["default"]})
    targets = for name <- ~w(alert dialog fresh), do: {"shadcn", name}
    targets = [{"ai_elements", "alert"} | targets]
    costs = VerificationShards.costs(previews, root)

    assert [slow, rest] = VerificationShards.plan(targets, previews, 2, costs)
    assert slow["components"] == ["shadcn/alert"]
    assert slow["weight"] == 100
    assert rest["components"] == ~w(ai_elements/alert shadcn/dialog shadcn/fresh)
    assert rest["weight"] == 35
  end
end

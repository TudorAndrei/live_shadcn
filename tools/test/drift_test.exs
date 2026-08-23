defmodule LiveShadcnTools.DriftTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Drift

  defp spec(tree, extra \\ %{}) do
    Map.merge(%{"parts" => [%{"name" => "thing", "tree" => tree}]}, extra)
  end

  defp element(attrs) do
    Map.merge(
      %{"type" => "element", "tag" => "div", "slot" => nil, "class" => "", "children" => []},
      attrs
    )
  end

  describe "what a reviewer needs to know" do
    test "a class string that moved is reported as a class string" do
      before = spec(element(%{"class" => "flex items-start"}))
      now = spec(element(%{"class" => "flex items-center"}))

      assert [{:added, "class string", ["flex items-center"]}, {:removed, "class string", _}] =
               Drift.between(before, now)
    end

    test "an attribute that appeared is reported first, because a recipe may not know it" do
      before = spec(element(%{"reads" => %{"self" => ["data-open"]}}))
      now = spec(element(%{"reads" => %{"self" => ["data-open", "data-closed"]}}))

      assert [{:added, "attribute", ["data-closed"]} | _] = Drift.between(before, now)
    end

    test "a part that appeared is a change to the anatomy" do
      before = spec(element(%{"slot" => "card"}))

      now =
        spec(element(%{"slot" => "card", "children" => [element(%{"slot" => "card-footer"})]}))

      assert {:added, "part", ["card-footer"]} in Drift.between(before, now)
    end

    test "a variant that appeared is a new value the component accepts" do
      table = fn values ->
        %{"variants" => %{"buttonVariants" => %{"variants" => %{"variant" => values}}}}
      end

      before = spec(element(%{}), table.(%{"default" => "a"}))
      now = spec(element(%{}), table.(%{"default" => "a", "ghost" => "b"}))

      assert {:added, "variant", ["variant=ghost"]} in Drift.between(before, now)
    end

    test "a spec that did not change reports nothing" do
      same = spec(element(%{"class" => "flex", "slot" => "card"}))

      assert Drift.between(same, same) == []
    end

    test "the comparison reaches every element, not only the root" do
      before = spec(element(%{"children" => [element(%{"class" => "p-2"})]}))
      now = spec(element(%{"children" => [element(%{"class" => "p-4"})]}))

      assert {:added, "class string", ["p-4"]} in Drift.between(before, now)
    end
  end

  describe "what the pull request says" do
    test "counts the changes rather than the lines" do
      drift = [
        %{
          name: "accordion",
          new?: false,
          changes: [{:added, "class string", ["a", "b"]}, {:added, "attribute", ["data-closed"]}]
        },
        %{name: "field", new?: true, changes: []}
      ]

      assert Drift.title(drift) ==
               "sync shadcn — 1 attribute, 2 class strings, 1 new component"
    end

    test "says so plainly when nothing moved" do
      assert Drift.title([]) =~ "nothing moved"
      assert Drift.report([]) =~ "matches the last commit"
    end

    test "names the component each change belongs to" do
      drift = [
        %{name: "accordion", new?: false, changes: [{:added, "attribute", ["data-closed"]}]}
      ]

      report = Drift.report(drift)

      assert report =~ "**accordion**"
      assert report =~ "added attribute: data-closed"
      assert report =~ "Read the snapshot diff first"
    end

    test "a class string is trimmed, because its length would bury the change" do
      long = String.duplicate("a", 100)
      drift = [%{name: "x", new?: false, changes: [{:added, "class string", [long]}]}]

      assert Drift.report(drift) =~ "…"
      refute Drift.report(drift) =~ long
    end
  end
end

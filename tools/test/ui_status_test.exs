defmodule LiveShadcnTools.UiStatusTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Ui.Status

  test "inventory renders excluded AI components and preserves their evidence" do
    root = Path.join(System.tmp_dir!(), "ui-status-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(root) end)
    File.mkdir_p!(Path.join(root, "packages"))
    File.mkdir_p!(Path.join(root, "registry"))

    inventory = %{
      "components" => [
        %{
          "source" => "ai_elements",
          "name" => "message",
          "tier" => 1,
          "recipe" => "presentational"
        }
      ],
      "recipes" => %{"core" => ["presentational"]}
    }

    File.write!(Path.join(root, "registry/INVENTORY.json"), Jason.encode!(inventory))
    File.write!(Path.join(root, "registry/UPSTREAM.json"), ~s({"files":{}}))
    evidence = ~s({"ai_elements/message":{"pass":true,"evidence":"prior-ai-evidence"}})
    evidence_path = Path.join(root, "registry/VERIFY.json")
    File.write!(evidence_path, evidence)

    File.cd!(root, fn ->
      Status.run([])
      rendered = File.read!(Path.join(root, "docs/INVENTORY.md"))
      assert rendered =~ "| `excluded` | 1 |"
      assert rendered =~ "| `message` | 1 | `presentational` | ⬛ excluded |"
      assert File.read!(evidence_path) == evidence
      Status.run(["--check", "--source", "shadcn", "--require-verified"])
    end)
  end
end

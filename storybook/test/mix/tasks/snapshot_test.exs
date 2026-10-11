defmodule Mix.Tasks.SnapshotTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "selects primitive and documentation snapshots for the shadcn source" do
    assert Mix.Tasks.Snapshot.scoped_components(
             ["button", "shadcn-message", "data-table", "typography", "attachments"],
             "shadcn"
           ) == ["button", "shadcn-message", "data-table", "typography"]
  end

  test "finds snapshot files that are not in the current example index", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "button-default.html"), "current")
    File.write!(Path.join(tmp_dir, "button-old-example.html"), "old")
    File.write!(Path.join(tmp_dir, "index.json"), "{}")

    assert Mix.Tasks.Snapshot.unexpected_snapshot_names(tmp_dir, ["button-default"]) == [
             "button-old-example"
           ]
  end

  test "checks outdated snapshot names within the selected components", %{tmp_dir: tmp_dir} do
    for name <- ["button-default", "button-old-example", "attachments-default"] do
      File.write!(Path.join(tmp_dir, name <> ".html"), "snapshot")
    end

    assert Mix.Tasks.Snapshot.unexpected_snapshot_names(tmp_dir, ["button-default"], ["button"]) ==
             ["button-old-example"]
  end

  test "Streamdown snapshots remain current across separate generated IDs" do
    for _run <- 1..2 do
      assert :ok == Mix.Tasks.Snapshot.run(["ai_elements-message", "reasoning", "--check"])
    end
  end

  test "sorts object keys inside JSON command attributes" do
    first =
      ~s([["dispatch",{"detail":{"id":"message-7","behavior":"smooth","align":"start","scrollMargin":null},"event":"message-scroller:scroll-to","to":"#messages"}]])

    second =
      ~s([["dispatch",{"to":"#messages","event":"message-scroller:scroll-to","detail":{"scrollMargin":null,"align":"start","behavior":"smooth","id":"message-7"}}]])

    for name <- ["phx-click", "data-lb-dismiss-command"] do
      {^name, canonical} = Mix.Tasks.Snapshot.canonicalize_json_attribute({name, first})

      assert canonical ==
               ~s([["dispatch",{"detail":{"align":"start","behavior":"smooth","id":"message-7","scrollMargin":null},"event":"message-scroller:scroll-to","to":"#messages"}]])

      assert {name, canonical} ==
               Mix.Tasks.Snapshot.canonicalize_json_attribute({name, second})
    end

    assert {"phx-hook", "LiveBase.Scroller"} =
             Mix.Tasks.Snapshot.canonicalize_json_attribute({"phx-hook", "LiveBase.Scroller"})
  end
end

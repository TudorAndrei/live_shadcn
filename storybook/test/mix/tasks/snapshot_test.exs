defmodule Mix.Tasks.SnapshotTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  test "finds snapshot files that are not in the current example index", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "button-default.html"), "current")
    File.write!(Path.join(tmp_dir, "button-old-example.html"), "old")
    File.write!(Path.join(tmp_dir, "index.json"), "{}")

    assert Mix.Tasks.Snapshot.unexpected_snapshot_names(tmp_dir, ["button-default"]) == [
             "button-old-example"
           ]
  end

  test "sorts object keys inside JSON LiveView command attributes" do
    first =
      ~s([["dispatch",{"detail":{"id":"message-7","behavior":"smooth","align":"start","scrollMargin":null},"event":"message-scroller:scroll-to","to":"#messages"}]])

    second =
      ~s([["dispatch",{"to":"#messages","event":"message-scroller:scroll-to","detail":{"scrollMargin":null,"align":"start","behavior":"smooth","id":"message-7"}}]])

    {"phx-click", canonical} =
      Mix.Tasks.Snapshot.canonicalize_json_attribute({"phx-click", first})

    assert canonical ==
             ~s([["dispatch",{"detail":{"align":"start","behavior":"smooth","id":"message-7","scrollMargin":null},"event":"message-scroller:scroll-to","to":"#messages"}]])

    assert {"phx-click", canonical} ==
             Mix.Tasks.Snapshot.canonicalize_json_attribute({"phx-click", second})

    assert {"phx-hook", "LiveBase.Scroller"} =
             Mix.Tasks.Snapshot.canonicalize_json_attribute({"phx-hook", "LiveBase.Scroller"})
  end
end

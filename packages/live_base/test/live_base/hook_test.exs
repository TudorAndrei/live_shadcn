defmodule LiveBase.HookTest do
  use ExUnit.Case, async: true

  @owners [
    LiveBase.Calendar,
    LiveBase.Carousel,
    LiveBase.Clipboard,
    LiveBase.Combobox,
    LiveBase.Command,
    LiveBase.Dialog,
    LiveBase.Disclosure,
    LiveBase.Drawer,
    LiveBase.InteractionTrigger,
    LiveBase.Listbox,
    LiveBase.Menubar,
    LiveBase.Popover,
    LiveBase.Questionnaire,
    LiveBase.RadioGroup,
    LiveBase.Resizable,
    LiveBase.ResponsiveDialog,
    LiveBase.Scroller,
    LiveBase.Shimmer,
    LiveBase.Slider,
    LiveBase.Tabs,
    LiveBase.Toast,
    LiveBase.ToggleGroup
  ]

  test "every hook name is a key of the colocated hooks manifest" do
    manifest =
      Path.join(Mix.Project.build_path(), "phoenix-colocated/live_base/index.js")
      |> File.read!()

    registered = Regex.scan(~r/\["([\w.]+)"\] = js_/, manifest, capture: :all_but_first)

    assert Enum.sort(List.flatten(registered)) == Enum.sort(Enum.map(@owners, & &1.hook()))
  end
end

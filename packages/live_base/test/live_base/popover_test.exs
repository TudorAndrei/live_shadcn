defmodule LiveBase.PopoverTest do
  use ExUnit.Case, async: true

  alias LiveBase.Popover

  defp ops(%Phoenix.LiveView.JS{ops: ops}), do: ops

  defp trigger_targets(js) do
    for [kind, %{attr: attr, to: to}] <- ops(js),
        kind in ["set_attr", "remove_attr", "toggle_attr"],
        trigger_attribute?(attr),
        do: to
  end

  defp trigger_attribute?([name | _]), do: trigger_attribute?(name)
  defp trigger_attribute?(name), do: name in ["data-popup-open", "data-pressed", "aria-expanded"]

  describe "a supplied trigger id" do
    test "open, close, toggle, and dismiss change that trigger" do
      trigger_id = "plan-control"

      for command <- [:open, :close, :toggle, :dismiss] do
        js = apply(Popover, command, [%Phoenix.LiveView.JS{}, "plan", [trigger_id: trigger_id]])

        assert trigger_targets(js) == List.duplicate("##{trigger_id}", 3)
      end
    end
  end
end

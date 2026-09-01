defmodule LiveBase.ListboxTest do
  use ExUnit.Case, async: true

  alias LiveBase.Listbox

  defp ops(%Phoenix.LiveView.JS{ops: ops}), do: ops

  describe "choosing with a supplied trigger id" do
    test "updates and closes the supplied trigger" do
      js =
        Listbox.choose(
          listbox: "plan",
          trigger_id: "plan-control",
          value: "pro",
          label: "Pro"
        )

      assert [
               ["set_attr", %{attr: ["data-value", "pro"], to: "#plan-control"}]
             ] =
               Enum.filter(
                 ops(js),
                 &match?(["set_attr", %{attr: ["data-value", "pro"], to: "#plan-control"}], &1)
               )

      close_targets =
        for [kind, %{attr: attr, to: to}] <- ops(js),
            kind in ["set_attr", "remove_attr"],
            close_attribute?(attr),
            do: to

      assert close_targets == ["#plan-control", "#plan-control", "#plan-control"]
    end
  end

  defp close_attribute?([name | _]), do: close_attribute?(name)
  defp close_attribute?(name), do: name in ["data-popup-open", "data-pressed", "aria-expanded"]
end

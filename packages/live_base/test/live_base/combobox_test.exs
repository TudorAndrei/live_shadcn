defmodule LiveBase.ComboboxTest do
  use ExUnit.Case, async: true

  alias LiveBase.Combobox

  test "keeps trigger, addon, chip, and clear state through LiveView patches" do
    assert [["ignore_attrs", %{attrs: trigger_attributes}]] =
             Combobox.owned_attributes(:trigger).ops

    assert trigger_attributes == [
             "aria-controls",
             "aria-expanded",
             "data-popup-open",
             "data-pressed"
           ]

    assert [["ignore_attrs", %{attrs: addon_attributes}]] = Combobox.owned_attributes(:addon).ops
    assert addon_attributes == ["aria-hidden"]

    assert [["ignore_attrs", %{attrs: label_attributes}]] = Combobox.owned_attributes(:label).ops
    assert label_attributes == ["aria-hidden"]

    assert [["ignore_attrs", %{attrs: chip_attributes}]] = Combobox.owned_attributes(:chip).ops
    assert chip_attributes == ["aria-hidden"]

    assert [["ignore_attrs", %{attrs: chip_remove_attributes}]] =
             Combobox.owned_attributes(:chip_remove).ops

    assert chip_remove_attributes == ["tabindex"]

    assert [["ignore_attrs", %{attrs: clear_attributes}]] = Combobox.owned_attributes(:clear).ops
    assert clear_attributes == ["data-visible", "hidden", "tabindex"]
  end
end

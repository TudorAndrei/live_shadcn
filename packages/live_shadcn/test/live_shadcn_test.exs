defmodule LiveShadcnTest do
  use ExUnit.Case, async: true

  test "the package exposes a module" do
    assert Code.ensure_loaded?(LiveShadcn)
  end
end

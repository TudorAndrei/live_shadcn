defmodule StorybookWeb.VerificationReloadTest do
  use ExUnit.Case, async: false

  @root Path.expand("../../..", __DIR__)

  test "Mix detects added and deleted identity inputs without reading badges at request time" do
    path = Path.join(@root, "packages/live_base/assets/js/verification-reload-fixture.js")
    Code.ensure_loaded!(StorybookWeb.Docs)
    assert function_exported?(StorybookWeb.Docs, :__mix_recompile__?, 0)
    refute StorybookWeb.Docs.__mix_recompile__?()
    refute File.exists?(path)

    try do
      File.write!(path, "export default {};\n")
      assert StorybookWeb.Docs.__mix_recompile__?()
    after
      File.rm!(path)
    end

    refute StorybookWeb.Docs.__mix_recompile__?()

    existing = Path.join(@root, "packages/live_base/assets/js/combobox.js")
    bytes = File.read!(existing)

    try do
      File.rm!(existing)
      assert StorybookWeb.Docs.__mix_recompile__?()
    after
      File.write!(existing, bytes)
    end

    refute StorybookWeb.Docs.__mix_recompile__?()
  end
end

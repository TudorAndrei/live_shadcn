defmodule LiveShadcnTools.PinnedShadcnStructureTest do
  use ExUnit.Case, async: true

  import LiveShadcnTools

  # These verbatim fixtures are from the shadcn commit in UPSTREAM.json.
  # Keep their imports: the extractor deliberately includes imports in structure.
  for name <- ~w(menubar navigation-menu popover slider toast) do
    @name name
    test "#{name} preserves the pinned source structure and class facts" do
      name = @name
      source_path = "shadcn/ui/#{name}.tsx"
      body = File.read!(Path.join(__DIR__, "fixtures/pinned_shadcn/#{name}.tsx"))
      manifest = read_json!(registry_path("UPSTREAM.json"))
      contract = read_json!(spec_path("shadcn", name))

      assert digest(body) == get_in(manifest, ["files", source_path, "sha256"])
      assert contract["upstream"][source_path] == digest(body)

      request =
        Path.join(System.tmp_dir!(), "pinned-facts-#{System.unique_integer([:positive])}.json")

      File.write!(request, Jason.encode!(%{files: %{source_path => body}}))
      on_exit(fn -> File.rm(request) end)
      script = Path.join(:code.priv_dir(:live_shadcn_tools), "facts.mjs")
      {output, status} = System.cmd("node", [script, request], stderr_to_stdout: true)
      assert status == 0, output
      extracted = Jason.decode!(output)["files"][source_path]
      assert contract["file_fingerprints"][source_path] == extracted["fingerprint"]

      for key <- contract["bindings"]["copy"] do
        assert contract["facts"][key] == Map.fetch!(extracted["facts"], key), "#{name}: #{key}"
      end

      for {key, %{"op" => "join", "items" => items}} <- contract["bindings"]["derived"] do
        expected = Enum.map_join(items, " ", &Map.fetch!(extracted["facts"], &1["fact"]))
        assert contract["facts"][key] == expected, "#{name}: #{key}"
      end
    end
  end
end

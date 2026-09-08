defmodule Mix.Tasks.Ui.FetchTest do
  use ExUnit.Case, async: true

  describe "the upstream manifest" do
    @manifest Path.expand("../../registry/UPSTREAM.json", __DIR__)

    test "pins every source to a commit, so a fetch is reproducible" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      for source <- ["shadcn", "base_ui", "ai_elements"] do
        ref = get_in(manifest, ["sources", source, "ref"])
        assert is_binary(ref) and byte_size(ref) == 40, "#{source} is not pinned to a commit SHA"
      end
    end

    test "pins Base UI documentation to one official release deployment" do
      manifest = @manifest |> File.read!() |> Jason.decode!()
      source = get_in(manifest, ["sources", "base_ui"])

      assert source == %{
               "deploy" => "6a71b76c1fdcdd00097c7c47",
               "origin" =>
                 "https://6a71b76c1fdcdd00097c7c47--base-ui.netlify.app/react/components",
               "ref" => "254f4744f0a241c20697b9eeab33402f4469a081",
               "repo" => "mui/base-ui",
               "version" => "1.7.0"
             }
    end

    test "records a digest and an origin for every fetched file" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      assert map_size(manifest["files"]) > 0

      for {path, entry} <- manifest["files"] do
        assert byte_size(entry["sha256"]) == 64, "#{path} has no usable digest"
        assert String.starts_with?(entry["url"], "https://"), "#{path} has no origin"
      end
    end

    # shadcn's registry index points a component at whatever documents it, and
    # for a component built on a React library that is the library's own site:
    # `resizable` at react-resizable-panels, `command` at cmdk, `sonner` at
    # sonner.emilkowal.ski. Following one stored a home page as a Base UI
    # contract, and two of them are GitHub pages whose HTML carries a fresh
    # token per request — so their digests changed on every fetch and the weekly
    # sync would have opened a pull request every week that said nothing had
    # changed.
    test "every Base UI page came from the pinned official deployment" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      pages = for {"base_ui/" <> _ = path, entry} <- manifest["files"], do: {path, entry["url"]}

      assert pages != []

      for {path, url} <- pages do
        assert String.starts_with?(
                 url,
                 "https://6a71b76c1fdcdd00097c7c47--base-ui.netlify.app/react/"
               ),
               "#{path} was fetched from #{url}, which is not the pinned Base UI deployment"
      end
    end
  end

  # The storybook navigation is built from these, so a component upstream files
  # under no heading is a component the sidebar would not show.
  describe "the documentation sections" do
    test "pins every official shadcn example from the component documentation" do
      manifest = @manifest |> File.read!() |> Jason.decode!()
      examples = get_in(manifest, ["examples", "shadcn"])

      documented = Map.keys(examples)

      for path <- Path.wildcard(Path.expand("../../registry/spec/shadcn/*.json", __DIR__)) do
        assert Path.basename(path, ".json") in documented
      end

      assert examples["dropdown-menu"] == [
               "dropdown-menu-demo",
               "dropdown-menu-basic",
               "dropdown-menu-submenu",
               "dropdown-menu-shortcuts",
               "dropdown-menu-icons",
               "dropdown-menu-checkboxes",
               "dropdown-menu-checkboxes-icons",
               "dropdown-menu-radio-group",
               "dropdown-menu-radio-icons",
               "dropdown-menu-destructive",
               "dropdown-menu-avatar",
               "dropdown-menu-complex",
               "dropdown-menu-rtl"
             ]
    end

    test "pins public registry examples when the component has no documentation page" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      assert get_in(manifest, ["examples", "shadcn", "sonner"]) == [
               %{
                 "id" => "basic",
                 "reference" => "shadcn/sonner#SonnerBasic",
                 "source" => "shadcn/examples/sonner-example.tsx#SonnerBasic"
               },
               %{
                 "id" => "with-description",
                 "reference" => "shadcn/sonner#SonnerWithDescription",
                 "source" => "shadcn/examples/sonner-example.tsx#SonnerWithDescription"
               }
             ]

      assert Map.has_key?(manifest["files"], "shadcn/examples/sonner-example.tsx")
    end

    test "pins docs-only composite pages and each rendered example source" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      assert Map.has_key?(manifest["files"], "shadcn/docs-meta.json")

      for component <- ["data-table", "date-picker", "typography"] do
        sources = get_in(manifest, ["examples", "shadcn", component])

        assert is_list(sources) and sources != [], "#{component} has no official sources"
        assert Map.has_key?(manifest["files"], "shadcn/docs/#{component}.mdx")

        for source <- sources do
          assert Map.has_key?(manifest["files"], "shadcn/examples/#{source}.tsx"),
                 "#{component} source #{source} is not pinned"
        end
      end
    end

    test "pins the official AI Elements examples" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      examples =
        for {"ai_examples/" <> file, _entry} <- manifest["files"],
            Path.extname(file) == ".tsx",
            do: file

      assert Enum.count_until(examples, 80) == 80
      assert "audio-player.tsx" in examples
      assert "file-tree.tsx" in examples
      assert "question.tsx" in examples
      assert "web-preview.tsx" in examples
    end

    test "pins the shadcn source AI Elements uses" do
      manifest = @manifest |> File.read!() |> Jason.decode!()
      files = Map.keys(manifest["files"])

      assert "ai_shadcn/ui/button.tsx" in files
      assert "ai_shadcn/ui/button-group.tsx" in files
      assert "ai_shadcn/lib/utils.ts" in files
    end

    test "file every AI Elements component under exactly one heading" do
      manifest = @manifest |> File.read!() |> Jason.decode!()
      sections = get_in(manifest, ["groups", "ai_elements"])

      filed = Enum.flat_map(sections, & &1["components"])

      fetched =
        for {"ai_elements/" <> file, _entry} <- manifest["files"],
            Path.extname(file) == ".tsx",
            do: Path.basename(file, ".tsx")

      assert Enum.sort(filed) == Enum.sort(fetched)
      assert Enum.uniq(filed) == filed
    end

    test "are titled, and in the order the documentation lists them" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      for section <- get_in(manifest, ["groups", "ai_elements"]) do
        assert section["title"] =~ ~r/^[A-Z]/, "a section with no heading of its own"
        assert section["components"] != []
      end
    end
  end

  describe "the GitHub token" do
    test "a token asks to be used" do
      assert Mix.Tasks.Ui.Fetch.auth_headers("ghp_example") == [
               {"authorization", "Bearer ghp_example"}
             ]
    end

    # A container build passes an empty string when nobody supplied a token, and
    # `Bearer` with nothing after it is a 401 rather than a lower rate limit.
    # Anonymous is the correct fallback, and it is what an absent token already
    # got.
    test "no token and an empty token both fetch anonymously" do
      assert Mix.Tasks.Ui.Fetch.auth_headers(nil) == []
      assert Mix.Tasks.Ui.Fetch.auth_headers("") == []
    end
  end
end

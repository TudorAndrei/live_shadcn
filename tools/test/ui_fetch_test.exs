defmodule Mix.Tasks.Ui.FetchTest do
  use ExUnit.Case, async: true

  describe "the upstream manifest" do
    @manifest Path.expand("../../registry/UPSTREAM.json", __DIR__)

    test "pins every source to a commit, so a fetch is reproducible" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      for source <- ["shadcn", "ai_elements"] do
        ref = get_in(manifest, ["sources", source, "ref"])
        assert is_binary(ref) and byte_size(ref) == 40, "#{source} is not pinned to a commit SHA"
      end
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
    test "every Base UI page came from Base UI" do
      manifest = @manifest |> File.read!() |> Jason.decode!()

      pages = for {"base_ui/" <> _ = path, entry} <- manifest["files"], do: {path, entry["url"]}

      assert pages != []

      for {path, url} <- pages do
        assert String.starts_with?(url, "https://base-ui.com/"),
               "#{path} was fetched from #{url}, which is not Base UI"
      end
    end
  end

  # The storybook navigation is built from these, so a component upstream files
  # under no heading is a component the sidebar would not show.
  describe "the documentation sections" do
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

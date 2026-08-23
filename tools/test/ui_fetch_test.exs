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

defmodule Mix.Tasks.Ui.Fetch do
  @shortdoc "Fetch upstream shadcn, Base UI, and AI Elements sources into registry/upstream"

  @moduledoc """
  Stage 1 of the codegen pipeline.

  Pins each upstream repository to a commit SHA, downloads the sources the later
  stages parse, and records a manifest of SHA-256 digests in
  `registry/UPSTREAM.json`.

  The manifest also records the sections the AI Elements documentation groups
  its components under, which is what the storybook navigation is built from.

  The downloaded files are gitignored. The manifest is not. A change upstream
  therefore shows up as a digest diff in the sync pull request, without this
  repository redistributing anybody else's source.

      mix ui.fetch                 # everything
      mix ui.fetch --only accordion
      mix ui.fetch --ref a1b2c3d   # pin shadcn to an explicit commit

  """
  use Mix.Task

  import LiveShadcnTools

  alias LiveShadcnTools.Style

  @shadcn_repo "shadcn-ui/ui"
  @ai_elements_repo "vercel/ai-elements"
  @shadcn_index "https://ui.shadcn.com/r/index.json"
  @shadcn_ui_dir "apps/v4/registry/bases/base/ui"
  @shadcn_styles_dir "apps/v4/registry/styles"
  @shadcn_styles_index "apps/v4/registry/styles.tsx"

  # The design tokens every `cn-` rule resolves against. Without them a rule
  # such as `focus-visible:ring-ring/50` is an unknown utility and the whole
  # style sheet fails to compile, so they are part of the styling contract.
  @shadcn_theme ["apps/v4/app/globals.css", "apps/v4/app/legacy-themes.css"]
  @ai_elements_dir "packages/elements/src"

  # The sections the AI Elements documentation files its components under —
  # Chatbot, Code, Voice, Workflow, Utilities — which the storybook navigation
  # is grouped by. Upstream keeps them in two places: the directory a page sits
  # in, `(chatbot)/attachments.mdx`, and `meta.json`, which titles the sections
  # and puts them in order.
  @ai_docs_dir "apps/docs/content/components"
  @base_ui_docs "https://base-ui.com/react/components"

  # Base UI is one site, and its pages are not all under one path: most
  # components live at `/react/components/`, but `direction-provider` lives at
  # `/react/utils/`. What makes a link a Base UI contract is the host.
  @base_ui_host "https://base-ui.com/"

  # Every registry source names its icons by their `lucide-react` export, and
  # some of those exports are aliases lucide has since renamed: `CheckCircleIcon`
  # is `CircleCheckBig` now, `Loader2Icon` is `LoaderCircle`, `MoreHorizontalIcon`
  # is `Ellipsis`. Kebab-cased as written they name icons an icon set does not
  # have, and seven of the forty-four in this registry drew the wrong glyph.
  #
  # The table is one line of lucide's own type declaration — `CircleCheckBig as
  # CheckCircleIcon`, twice per icon — so it is fetched with everything else
  # rather than typed here, where it would go stale the next time lucide renames
  # one. The version is pinned, and `parity/package.json` installs the same one:
  # the React the components are compared against has to draw the same glyphs.
  @lucide_version "1.32.0"

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(argv, strict: [only: :string, ref: :string])
    only = opts[:only]

    shadcn_ref = opts[:ref] || resolve_ref(@shadcn_repo)
    ai_ref = resolve_ref(@ai_elements_repo)

    Mix.shell().info("shadcn-ui/ui      @ #{shadcn_ref}")
    Mix.shell().info("vercel/ai-elements @ #{ai_ref}")

    index = fetch_json(@shadcn_index)
    components = Enum.filter(index, &keep?(&1, only))

    Mix.shell().info("fetching #{length(components)} shadcn components")

    shadcn_files = Enum.flat_map(components, &fetch_component(&1, shadcn_ref))
    {style_files, styles} = fetch_styles(shadcn_ref)
    {ai_files, ai_sections} = if only, do: {[], []}, else: fetch_ai_elements(ai_ref)
    lucide_files = if only, do: [], else: fetch_lucide()

    manifest = %{
      "generated_by" => "mix ui.fetch",
      "styles" => styles,
      "sources" => %{
        "shadcn" => %{"repo" => @shadcn_repo, "ref" => shadcn_ref, "dir" => @shadcn_ui_dir},
        "base_ui" => %{"origin" => "https://base-ui.com/react/components"},
        "ai_elements" => %{
          "repo" => @ai_elements_repo,
          "ref" => ai_ref,
          "dir" => @ai_elements_dir
        },
        "lucide" => %{"package" => "lucide-react", "version" => @lucide_version}
      },
      "groups" => %{"ai_elements" => ai_sections},
      "files" => Map.new(shadcn_files ++ style_files ++ ai_files ++ lucide_files)
    }

    manifest =
      if only do
        # A partial fetch must not delete digests it did not refresh, and it
        # reads no documentation index at all.
        previous = existing_manifest()

        manifest
        |> put_in(["files"], Map.merge(previous["files"] || %{}, manifest["files"]))
        |> put_in(["groups"], previous["groups"] || %{})
      else
        manifest
      end

    write_json!(registry_path("UPSTREAM.json"), manifest)

    case Process.get(:no_page, []) |> Enum.uniq() |> Enum.sort() do
      [] -> :ok
      names -> Mix.shell().info("no Base UI page (presentational): #{Enum.join(names, ", ")}")
    end

    Mix.shell().info("wrote registry/UPSTREAM.json (#{map_size(manifest["files"])} files)")
  end

  defp keep?(_item, nil), do: true
  defp keep?(%{"name" => name}, only), do: name == only

  defp fetch_component(%{"name" => name} = item, ref) do
    tsx_url = raw_url(@shadcn_repo, ref, "#{@shadcn_ui_dir}/#{name}.tsx")

    {tsx, source} =
      case get(tsx_url) do
        {:ok, body} -> {[store("shadcn/ui/#{name}.tsx", body, tsx_url)], body}
        {:error, status} -> {warn(name, "component source", status), ""}
      end

    # The registry index links a Base UI page for most components and not all.
    # Where it does not, the page is looked for under the component's own name,
    # because Base UI publishes more pages than shadcn links to — `button` and
    # `field` among them.
    link = base_ui_link(item) || page_url(name)

    # A component may be built from more than one Base UI module: menubar uses
    # both `menubar` and `menu`, toggle-group both `toggle-group` and `toggle`.
    # Each module has its own page, and each page is the contract for the parts
    # it documents, so all of them are fetched.
    modules = base_ui_modules(source)

    tsx ++
      fetch_base_ui(name, link) ++ Enum.flat_map(modules, &fetch_base_ui(&1, page_url(&1)))
  end

  defp page_url(module), do: "#{@base_ui_docs}/#{module}.md"

  # The index's `base.api` link is not always a Base UI page. A component built
  # on a React library points at that library: `resizable` at
  # react-resizable-panels, `command` at cmdk, `calendar` at react-day-picker,
  # `sonner` at its own site. Following one stored a home page as that
  # component's Base UI contract.
  #
  # Two of those links are GitHub repository pages, and GitHub puts a fresh page
  # token in every response, so their digests changed on every fetch and the
  # weekly sync would have opened a pull request saying nothing had changed.
  #
  # Match on the host, not the path. `direction` is a real Base UI page and it
  # lives under `/react/utils/` rather than `/react/components/`. A link
  # anywhere else means the component has no Base UI page, which is what the
  # spec reader already reports for each of them.
  defp base_ui_link(item) do
    case get_in(item, ["meta", "links", "base", "api"]) do
      @base_ui_host <> _rest = link -> link
      _other -> nil
    end
  end

  defp base_ui_modules(source) do
    ~r|from "@base-ui/react/([a-z0-9-]+)"|
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  # A page named by two components is downloaded once per run, not twice.
  defp fetch_base_ui(name, url) do
    path = "base_ui/#{name}.md"

    if stored?(path) do
      []
    else
      case get(url) do
        {:ok, body} ->
          [store(path, body, url)]

        {:error, _status} ->
          # Normal, not a failure. A card is a `<div>` with a class string, and
          # Base UI has nothing to say about it.
          Process.put(:no_page, [name | Process.get(:no_page, [])])
          []
      end
    end
  end

  defp stored?(path), do: MapSet.member?(Process.get(:stored, MapSet.new()), path)

  # The `cn-` classes every class string starts with are defined here, one
  # sheet per shadcn style. They are fetched whatever `--only` says, because a
  # sheet covers every component at once and a component without its rules is a
  # component without its styling.
  defp fetch_styles(ref) do
    index = raw_url(@shadcn_repo, ref, @shadcn_styles_index)

    case get(index) do
      {:error, status} ->
        {warn("styles", "style index", status), %{}}

      {:ok, body} ->
        names = Style.names(body)
        Mix.shell().info("fetching #{length(names)} style sheets")

        files =
          [store("shadcn/styles.tsx", body, index)] ++
            Enum.flat_map(names, &fetch_style(&1, ref)) ++
            Enum.flat_map(@shadcn_theme, &fetch_theme(&1, ref))

        {files, %{"available" => names, "default" => List.first(names)}}
    end
  end

  # Stored under the name each file imports the next by, so the chain of
  # `@import` statements upstream wrote still resolves on disk.
  defp fetch_theme(path, ref) do
    url = raw_url(@shadcn_repo, ref, path)

    case get(url) do
      {:ok, body} -> [store("shadcn/theme/#{Path.basename(path)}", body, url)]
      {:error, status} -> warn(Path.basename(path), "theme", status)
    end
  end

  defp fetch_style(name, ref) do
    url = raw_url(@shadcn_repo, ref, "#{@shadcn_styles_dir}/style-#{name}.css")

    case get(url) do
      {:ok, body} -> [store("shadcn/styles/#{name}.css", body, url)]
      {:error, status} -> warn(name, "style sheet", status)
    end
  end

  defp fetch_ai_elements(ref) do
    tree =
      fetch_json("https://api.github.com/repos/#{@ai_elements_repo}/git/trees/#{ref}?recursive=1")

    sources =
      tree["tree"]
      |> Enum.filter(fn node ->
        node["type"] == "blob" and String.starts_with?(node["path"], @ai_elements_dir <> "/") and
          String.ends_with?(node["path"], ".tsx")
      end)
      |> tap(&Mix.shell().info("fetching #{length(&1)} AI Elements components"))
      |> Enum.flat_map(fn node ->
        url = raw_url(@ai_elements_repo, ref, node["path"])
        name = node["path"] |> Path.basename(".tsx")

        case get(url) do
          {:ok, body} -> [store("ai_elements/#{name}.tsx", body, url)]
          {:error, status} -> warn(name, "AI Elements source", status)
        end
      end)

    {index, sections} = fetch_ai_sections(tree["tree"], ref)
    {sources ++ index, sections}
  end

  # The documentation index, and the sections it puts the components in.
  defp fetch_ai_sections(tree, ref) do
    url = raw_url(@ai_elements_repo, ref, "#{@ai_docs_dir}/meta.json")

    case get(url) do
      {:ok, body} ->
        sections = sections(Jason.decode!(body)["pages"], documented(tree))
        Mix.shell().info("#{length(sections)} documentation sections")
        {[store("ai_elements/docs-meta.json", body, url)], sections}

      {:error, status} ->
        {warn("ai-elements", "the documentation index", status), []}
    end
  end

  # Every documentation page, under the directory it sits in.
  defp documented(tree) do
    for %{"type" => "blob", "path" => path} <- tree,
        String.starts_with?(path, @ai_docs_dir <> "/"),
        String.ends_with?(path, ".mdx"),
        reduce: %{} do
      pages ->
        directory = path |> Path.dirname() |> Path.basename()

        Map.update(
          pages,
          directory,
          [Path.basename(path, ".mdx")],
          &[Path.basename(path, ".mdx") | &1]
        )
    end
  end

  # `meta.json` writes a heading as `---Chatbot---` and its contents as
  # `...(chatbot)`, which is the documentation framework's own notation for
  # "every page in that directory". A page named on its own is named on its own.
  defp sections(entries, pages) do
    entries |> Enum.reduce([], &section(&1, &2, pages)) |> Enum.reverse()
  end

  defp section("---" <> heading, sections, _pages) do
    [%{"title" => String.trim_trailing(heading, "---"), "components" => []} | sections]
  end

  defp section(_entry, [], _pages), do: []

  defp section("..." <> directory, [current | rest], pages) do
    [add(current, pages |> Map.get(directory, []) |> Enum.sort()) | rest]
  end

  defp section(name, [current | rest], _pages), do: [add(current, [name]) | rest]

  defp add(section, names), do: %{section | "components" => section["components"] ++ names}

  defp fetch_lucide do
    url = "https://cdn.jsdelivr.net/npm/lucide-react@#{@lucide_version}/dist/lucide-react.d.ts"

    case get(url) do
      {:ok, body} -> [store("lucide/lucide-react.d.ts", body, url)]
      {:error, status} -> warn("lucide-react", "the icon alias table", status)
    end
  end

  defp store(relative, body, url) do
    write!(registry_path(["upstream", relative]), body)
    Process.put(:stored, MapSet.put(Process.get(:stored, MapSet.new()), relative))
    {relative, %{"sha256" => digest(body), "url" => url, "bytes" => byte_size(body)}}
  end

  defp warn(name, what, status) do
    Mix.shell().error("  skip #{name}: #{what} returned #{status}")
    []
  end

  defp existing_manifest do
    path = registry_path("UPSTREAM.json")
    if File.exists?(path), do: read_json!(path), else: %{"files" => %{}}
  end

  defp resolve_ref(repo) do
    fetch_json("https://api.github.com/repos/#{repo}/commits/main")["sha"]
  end

  defp raw_url(repo, ref, path), do: "https://raw.githubusercontent.com/#{repo}/#{ref}/#{path}"

  defp fetch_json(url) do
    case get(url) do
      {:ok, body} -> Jason.decode!(body)
      {:error, status} -> Mix.raise("GET #{url} failed with status #{status}")
    end
  end

  defp get(url) do
    case Req.get(url, headers: headers(), retry: :transient, max_retries: 3) do
      {:ok, %{status: 200, body: body}} -> {:ok, to_binary(body)}
      {:ok, %{status: status}} -> {:error, status}
      {:error, reason} -> Mix.raise("GET #{url} failed: #{inspect(reason)}")
    end
  end

  # Req decodes JSON responses for us; the pipeline wants the raw bytes so the
  # digest matches what upstream actually serves.
  defp to_binary(body) when is_binary(body), do: body
  defp to_binary(body), do: Jason.encode!(body)

  defp headers, do: auth_headers(System.get_env("GITHUB_TOKEN"))

  @doc """
  The authorization header a token asks for, if it asks for one.

  An unset token and an empty one mean the same thing: fetch anonymously and
  live with the lower rate limit. They did not, and an empty one is exactly what
  a container build passes when nobody supplied a token — `Bearer` with nothing
  after it is a 401, so the build failed where it should have carried on.
  """
  def auth_headers(token) when token in [nil, ""], do: []
  def auth_headers(token), do: [{"authorization", "Bearer #{token}"}]
end

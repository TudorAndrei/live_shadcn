defmodule LiveShadcnTools.ColocatedHooks do
  @moduledoc """
  Writes each hook from a package's `assets/js/` into the colocated hook block
  of the component that uses it.

  A block sits inside a `~H` template, between two markers:

      <%!-- colocated-hook floating.js#Floating --%>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Floating">
        ...
      </script>
      <%!-- /colocated-hook --%>

  The opening marker names the entry, relative to the package's `assets/js/`,
  and the export that is the hook. LiveView extracts the script to `_build/`,
  where a relative import does not resolve. So the script holds the entry with
  its relative imports inlined by rolldown, see `priv/colocated_hook.mjs`. Bare
  imports stay `import` statements for the application's bundler.

  The JavaScript files stay the source. Every block is generated.
  """

  import LiveShadcnTools, only: [repo_root: 0]

  @packages ~w(live_base live_ai_elements)
  @open ~r/^([ \t]*)<%!-- colocated-hook (\S+)#([A-Za-z_$][\w$]*) --%>[ \t]*\r?$/
  @close ~r/^[ \t]*<%!-- \/colocated-hook --%>[ \t]*\r?$/

  @doc """
  Renders every block under the packages' `lib/` directories.

  Returns the files whose content changes, each with its path relative to the
  repository root and its new content, or every problem found.
  """
  def render(root \\ repo_root()) do
    {blocks, errors} =
      @packages
      |> Enum.flat_map(&Path.wildcard(Path.join([root, "packages", &1, "lib", "**", "*.ex"])))
      |> Enum.sort()
      |> Enum.map(&scan(root, &1))
      |> Enum.reduce({[], []}, fn {file_blocks, file_errors}, {blocks, errors} ->
        {blocks ++ file_blocks, errors ++ file_errors}
      end)

    errors = errors ++ Enum.flat_map(blocks, &entry_error(root, &1))

    # The packages hold hooks, so finding none means the scan read the wrong
    # tree, and reporting it current would hide that.
    errors =
      if blocks == [] and errors == [],
        do: ["no colocated hook blocks under packages/{#{Enum.join(@packages, ",")}}/lib"],
        else: errors

    with [] <- errors,
         {:ok, bundles} <- bundle(root, blocks) do
      blocks
      |> Enum.group_by(& &1.path)
      |> Enum.sort()
      |> Enum.flat_map(&rewrite(root, &1, bundles))
      |> then(&{:ok, &1})
    else
      {:error, errors} -> {:error, errors}
      errors -> {:error, errors}
    end
  end

  defp scan(root, path) do
    lines = path |> File.read!() |> String.split("\n")
    relative = Path.relative_to(path, root)
    package = path |> Path.relative_to(Path.join(root, "packages")) |> Path.split() |> hd()

    lines
    |> Enum.with_index(1)
    |> Enum.reduce({nil, [], []}, fn {line, number}, {open, blocks, errors} ->
      case {open, Regex.run(@open, line), Regex.match?(@close, line)} do
        {nil, [_, indent, entry, name], _} ->
          block = %{
            path: relative,
            package: package,
            line: number,
            indent: indent,
            entry: entry,
            export: name
          }

          {block, blocks, errors}

        {nil, nil, true} ->
          {nil, blocks, errors ++ ["#{relative}:#{number}: a closing marker without an opening"]}

        {block, [_ | _], _} ->
          {block, blocks, errors ++ ["#{relative}:#{block.line}: the block is not closed"]}

        {block, nil, true} when block != nil ->
          {nil, blocks ++ [Map.put(block, :last, number)], errors}

        _ ->
          {open, blocks, errors}
      end
    end)
    |> case do
      {nil, blocks, errors} ->
        {blocks, errors}

      {open, blocks, errors} ->
        {blocks, errors ++ ["#{relative}:#{open.line}: the block is not closed"]}
    end
  end

  defp entry_error(root, block) do
    cond do
      Path.safe_relative(block.entry) == :error ->
        ["#{block.path}:#{block.line}: #{block.entry} is outside assets/js/"]

      not File.regular?(entry_path(root, block)) ->
        [
          "#{block.path}:#{block.line}: packages/#{block.package}/assets/js/#{block.entry} does not exist"
        ]

      true ->
        []
    end
  end

  defp entry_path(root, block),
    do: Path.join([root, "packages", block.package, "assets", "js", block.entry])

  # The bundler writes its reply to a file of its own. What it prints, on
  # stdout or stderr, is diagnostics and appears only when the run fails.
  defp bundle(root, blocks) do
    keys = blocks |> Enum.map(&{entry_path(root, &1), &1.export}) |> Enum.uniq()
    request = %{hooks: Enum.map(keys, fn {entry, name} -> %{entry: entry, export: name} end)}

    base = Path.join(System.tmp_dir!(), "live-shadcn-hooks-#{System.unique_integer([:positive])}")
    request_path = base <> "-request.json"
    reply_path = base <> "-reply.json"
    script = Path.join(:code.priv_dir(:live_shadcn_tools), "colocated_hook.mjs")
    File.write!(request_path, Jason.encode!(request))

    try do
      with {:ok, node} <- find_node(),
           {output, 0} <-
             System.cmd(node, [script, request_path, reply_path],
               stderr_to_stdout: true,
               env: [{"NO_COLOR", "1"}]
             ),
           {:ok, hooks} <- reply(reply_path, length(keys), output) do
        results(root, blocks, keys, hooks)
      else
        {:error, errors} -> {:error, errors}
        {output, status} -> {:error, ["the hook bundler exited with #{status}:\n#{output}"]}
      end
    after
      File.rm(request_path)
      File.rm(reply_path)
    end
  end

  defp reply(path, count, output) do
    with {:ok, json} <- File.read(path),
         {:ok, %{"hooks" => hooks}} when is_list(hooks) <- Jason.decode(json),
         true <- length(hooks) == count and Enum.all?(hooks, &hook_result?/1) do
      {:ok, hooks}
    else
      _ -> {:error, ["the hook bundler did not reply with #{count} hook results:\n#{output}"]}
    end
  end

  defp hook_result?(%{"code" => code}) when is_binary(code), do: true
  defp hook_result?(%{"error" => error}) when is_binary(error), do: true
  defp hook_result?(_result), do: false

  # `reply/3` checked that there is one result per key, so every block's key
  # is in `bundles`.
  defp results(root, blocks, keys, hooks) do
    bundles = keys |> Enum.zip(hooks) |> Map.new()

    errors =
      for block <- blocks,
          %{"error" => error} <- [Map.get(bundles, {entry_path(root, block), block.export})],
          do: "#{block.path}:#{block.line}: #{error}"

    if errors == [],
      do: {:ok, Map.new(bundles, fn {key, %{"code" => code}} -> {key, code} end)},
      else: {:error, errors}
  end

  defp rewrite(root, {relative, blocks}, bundles) do
    path = Path.join(root, relative)
    current = File.read!(path)
    lines = String.split(current, "\n")
    # A file with CRLF line endings keeps them inside the blocks too.
    cr = if String.contains?(current, "\r\n"), do: "\r", else: ""

    {rendered, rest} =
      Enum.reduce(blocks, {[], {1, lines}}, fn block, {acc, {number, rest}} ->
        {before, tail} = Enum.split(rest, block.line - number)
        {_old, after_block} = Enum.split(tail, block.last - block.line + 1)
        code = Map.fetch!(bundles, {entry_path(root, block), block.export})
        block_lines = Enum.map(render_block(block, code), &(&1 <> cr))
        {acc ++ before ++ block_lines, {block.last + 1, after_block}}
      end)

    content = Enum.join(rendered ++ elem(rest, 1), "\n")

    if content == current, do: [], else: [{relative, content}]
  end

  defp render_block(block, code) do
    body =
      code
      |> String.trim_trailing("\n")
      |> String.split("\n")
      |> Enum.map(fn
        "" -> ""
        line -> block.indent <> "  " <> line
      end)

    [
      "#{block.indent}<%!-- colocated-hook #{block.entry}##{block.export} --%>",
      ~s(#{block.indent}<script :type={Phoenix.LiveView.ColocatedHook} name=".#{block.export}">)
      | body
    ] ++ ["#{block.indent}</script>", "#{block.indent}<%!-- /colocated-hook --%>"]
  end

  defp find_node do
    case System.find_executable("node") do
      nil -> {:error, ["node is not on PATH; run `mise install` before generating hooks"]}
      node -> {:ok, node}
    end
  end
end

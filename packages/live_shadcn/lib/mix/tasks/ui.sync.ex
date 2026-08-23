defmodule Mix.Tasks.Ui.Sync do
  @shortdoc "Report what changed in the registry since you copied a component"

  @moduledoc """
  Compares the components you installed against the registry.

      mix ui.sync                    # report every installed component
      mix ui.sync button             # one of them
      mix ui.sync --apply            # update the ones you have not edited
      mix ui.sync --diff button      # show the change

  Three answers per file, and only three:

  | | |
  |---|---|
  | `current` | your copy and the registry agree |
  | `behind` | the registry moved and your copy did not |
  | `edited` | you changed the file |

  **An edited file is never overwritten.** Not with `--apply`, not silently, not
  at all: the whole point of copying the source in is that it becomes yours.
  `--diff` shows what upstream did so you can decide, and re-adding with
  `mix ui.add --force` is the explicit way to discard your changes.

  This is what a component library owes you when it writes into your repository.
  A dependency can be upgraded behind your back; a file in your `lib/` cannot.
  """
  use Mix.Task

  alias LiveShadcn.Registry

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {parsed, names, _} =
      OptionParser.parse(argv, strict: [apply: :boolean, diff: :boolean, into: :string])

    opts = %{
      apply?: Keyword.get(parsed, :apply, false),
      diff?: Keyword.get(parsed, :diff, false),
      into: parsed[:into]
    }

    installed = installed(opts.into)
    wanted = if names == [], do: installed, else: Enum.filter(installed, &(&1.name in names))

    if wanted == [] do
      Mix.shell().info("nothing installed yet. `mix ui.add button` copies a component in.")
    else
      wanted |> Enum.map(&compare/1) |> report(opts)
    end
  end

  defp installed(into) do
    (into || Path.join(["lib", "**", "components", "ui"]))
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> Enum.flat_map(fn path ->
      case Registry.installed(path) do
        {:ok, file} -> [file]
        :error -> []
      end
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp compare(file) do
    case Registry.source(file.name) do
      :error ->
        %{file: file, state: :gone, registry: nil}

      {:ok, source} ->
        registry = Registry.body_of(source)

        state =
          cond do
            file.edited? -> :edited
            same?(file.body, registry) -> :current
            true -> :behind
          end

        %{file: file, state: state, registry: registry}
    end
  end

  # The module name is not a difference: `mix ui.add` rewrote it on the way in.
  # Everything else is compared byte for byte.
  defp same?(body, registry), do: without_module(body) == without_module(registry)

  defp without_module(source),
    do: Regex.replace(~r/^defmodule \S+ do$/m, source, "defmodule _ do")

  defp report(results, opts) do
    for %{file: file, state: state} = result <- results do
      Mix.shell().info("  #{pad(state)} #{file.name}  #{file.path}")

      if opts.diff? and state in [:behind, :edited], do: diff(result)
    end

    behind = Enum.filter(results, &(&1.state == :behind))
    edited = Enum.filter(results, &(&1.state == :edited))

    if opts.apply?, do: Enum.each(behind, &apply_update/1)

    summary(results, behind, edited, opts)
  end

  defp summary(results, behind, edited, opts) do
    Mix.shell().info("")

    Mix.shell().info(
      "#{length(results)} installed, #{length(behind)} behind, #{length(edited)} edited"
    )

    if edited != [] do
      Mix.shell().info("""

      Edited files are left alone. `mix ui.sync --diff #{hd(edited).file.name}` shows
      what upstream changed; `mix ui.add #{hd(edited).file.name} --force` discards
      your changes and takes the registry's version.
      """)
    end

    if behind != [] and not opts.apply? do
      Mix.shell().info("`mix ui.sync --apply` updates the #{length(behind)} unedited file(s).")
    end
  end

  # The file keeps the namespace it was installed under, so an update is the
  # registry's new bytes under the application's own module name.
  defp apply_update(%{file: file, registry: registry}) do
    namespace =
      case Regex.run(~r/^defmodule (\S+)\.\w+ do$/m, file.body, capture: :all_but_first) do
        [namespace] -> namespace
        nil -> "LiveShadcn.UI"
      end

    contents = Registry.install(registry, file.name, namespace: namespace, ref: file.ref)

    File.write!(file.path, contents)
    Mix.shell().info("  updated  #{file.path}")
  end

  defp diff(%{file: file, registry: registry}) do
    Mix.shell().info("")

    file.body
    |> String.myers_difference(registry)
    |> Enum.each(fn
      {:eq, _} -> :ok
      {:del, text} -> Mix.shell().info(prefix(text, "  - "))
      {:ins, text} -> Mix.shell().info(prefix(text, "  + "))
    end)

    Mix.shell().info("")
  end

  defp prefix(text, marker),
    do: text |> String.split("\n") |> Enum.map_join("\n", &(marker <> &1))

  defp pad(state), do: state |> to_string() |> String.pad_trailing(8)
end

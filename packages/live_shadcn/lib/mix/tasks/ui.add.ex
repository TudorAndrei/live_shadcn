defmodule Mix.Tasks.Ui.Add do
  @shortdoc "Copy components from the live_shadcn registry into your application"

  @moduledoc """
  Copies a component's source into your application, the way the shadcn CLI
  does, so you own the file and can edit it.

      mix ui.add button
      mix ui.add button card accordion
      mix ui.add --list                     # what the registry holds
      mix ui.add button --into lib/ui       # somewhere other than the default

  The default destination is `lib/<your_app>_web/components/ui/`, and the module
  is rewritten to match: `LiveShadcn.UI.Button` becomes
  `MyAppWeb.Components.UI.Button`.

  Every copy is stamped with the registry version it came from and a digest of
  its own body. That stamp is what lets `mix ui.sync` tell an untouched copy
  from one you have edited, and it is why an existing file is never overwritten
  without `--force`.

  ## Behavior and styling

  A component's behavior lives in `live_base`, which stays a dependency. Add its
  hooks to your `LiveSocket`:

      import { hooks as liveBase } from "live_base"
      new LiveSocket("/live", Socket, { hooks: { ...liveBase } })
  """
  use Mix.Task

  alias LiveShadcn.Registry

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, names, _} =
      OptionParser.parse(argv, strict: [into: :string, force: :boolean, list: :boolean])

    cond do
      opts[:list] ->
        list()

      names == [] ->
        Mix.raise("which components? `mix ui.add button card`, or `mix ui.add --list`")

      true ->
        Enum.each(names, &add(&1, opts))
    end
  end

  defp list do
    Mix.shell().info("the registry holds #{length(Registry.components())} components:\n")
    Mix.shell().info("  " <> Enum.join(Registry.components(), "\n  "))
  end

  defp add(name, opts) do
    case Registry.source(name) do
      :error ->
        Mix.shell().error("  no component called #{name}. `mix ui.add --list` shows them all.")

      {:ok, source} ->
        write(name, source, opts)
    end
  end

  defp write(name, source, opts) do
    directory = opts[:into] || default_directory()
    path = Path.join(directory, "#{String.replace(name, "-", "_")}.ex")

    contents =
      Registry.install(source, name, namespace: namespace(opts), ref: registry_ref())

    cond do
      not File.exists?(path) ->
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, contents)
        Mix.shell().info("  added   #{path}")

      opts[:force] ->
        File.write!(path, contents)
        Mix.shell().info("  replaced #{path}")

      true ->
        Mix.shell().error("""
          exists  #{path}

          `mix ui.sync #{name}` shows what changed upstream. Use --force to
          replace the file, which discards anything you changed in it.
        """)
    end
  end

  # `lib/my_app_web/components/ui`, which is where a Phoenix application already
  # keeps its components.
  defp default_directory do
    Path.join(["lib", "#{Mix.Project.config()[:app]}_web", "components", "ui"])
  end

  defp namespace(opts) do
    case opts[:into] do
      nil -> "#{Macro.camelize("#{Mix.Project.config()[:app]}")}Web.Components.UI"
      into -> into |> Path.split() |> Enum.drop(1) |> Enum.map_join(".", &Macro.camelize/1)
    end
  end

  # The registry's own version. A copy that cannot name where it came from
  # cannot be synced.
  defp registry_ref do
    case :application.get_key(:live_shadcn, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end

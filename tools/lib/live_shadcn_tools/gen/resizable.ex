defmodule LiveShadcnTools.Gen.Resizable do
  @moduledoc "The pointer-resizable panel recipe."

  alias LiveShadcnTools.Gen.Presentational

  @doc "The module source for a resizable panel group."
  def module(spec, opts) do
    spec
    |> Presentational.module(opts)
    |> String.replace(
      "  use Phoenix.Component\n",
      "  use Phoenix.Component\n\n  alias LiveBase.Resizable\n",
      global: false
    )
    |> String.replace(
      ~s|data-slot={@rest[:"data-slot"] \|\| "resizable-panel-group"}|,
      ~s|data-slot={@rest[:"data-slot"] \|\| "resizable-panel-group"}
      phx-hook={Resizable.hook()}
      aria-orientation={@orientation}|,
      global: false
    )
    |> String.replace(
      ~s|data-slot={@rest[:"data-slot"] \|\| "resizable-handle"}|,
      ~s|data-slot={@rest[:"data-slot"] \|\| "resizable-handle"}
      data-lb-resizable-handle
      role="separator"
      tabindex="0"
      aria-orientation={@orientation}|,
      global: false
    )
    |> String.replace(
      "  def resizable_handle(assigns) do",
      "  attr :orientation, :string, default: \"vertical\", values: [\"horizontal\", \"vertical\"]\n\n  def resizable_handle(assigns) do",
      global: false
    )
    |> String.replace(
      "  def resizable_panel_group(assigns) do",
      "  attr :orientation, :string, default: \"horizontal\", values: [\"horizontal\", \"vertical\"]\n\n  def resizable_panel_group(assigns) do",
      global: false
    )
  end
end

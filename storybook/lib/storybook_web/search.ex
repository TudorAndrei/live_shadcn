defmodule StorybookWeb.Search do
  @moduledoc """
  The ⌘K palette, built out of `<.command>` and `<.dialog>`.

  ## Who filters

  The server, and that is the same decision `command` was generated under: the
  server owns the list, so the caller filters it and the component draws what it
  is given. cmdk matches in the browser; a copy of the list held there would
  disagree with the server the moment either changed.

  It costs one round trip per keystroke, which is stated rather than hidden. For
  72 names that is a `String.contains?` over a list, and the alternative is a
  second copy of the list plus a matching rule to keep in step with it.

  ## What costs nothing

  Opening and closing. ⌘K is a `phx-window-keydown` carrying a `JS` command, so
  the palette appears without asking the server anything — the same rule every
  other component here is held to.
  """

  use StorybookWeb, :html

  import LiveShadcn.UI.Command
  import LiveShadcn.UI.Dialog

  alias StorybookWeb.Docs

  @id "docs-search"

  @doc "The id the dialog and its opener agree on."
  def id, do: @id

  @doc "Every component whose name contains the query, in listed order."
  def matches(query) do
    query = query |> to_string() |> String.trim() |> String.downcase()

    StorybookWeb.Examples.components()
    |> Enum.filter(&String.contains?(&1, query))
    |> Enum.sort()
  end

  attr :matches, :list, default: []

  def search(assigns) do
    assigns = assign(assigns, :id, @id)

    ~H"""
    <%!-- ⌘K anywhere on the page. `phx-key` filters one key, so the modifier is
          checked by the command rather than by a hook. --%>
    <div
      id={"#{@id}-shortcut"}
      phx-window-keydown={open(@id)}
      phx-key="k"
      class="contents"
    >
    </div>

    <.dialog id={@id} title_class="sr-only" description_class="sr-only">
      <:trigger>
        <span class="flex w-full items-center justify-between gap-2 text-sm text-muted-foreground">
          Search components <kbd class="rounded border px-1 text-xs">⌘K</kbd>
        </span>
      </:trigger>
      <:title>Search components</:title>
      <:description>Type part of a component's name.</:description>

      <.command>
        <form id={"#{@id}-form"} phx-change="search" phx-submit="search">
          <.command_input
            name="query"
            value=""
            placeholder="Search components…"
            phx-debounce="120"
            autocomplete="off"
          />
        </form>

        <.command_list>
          <.command_empty :if={@matches == []}>
            Nothing by that name.
          </.command_empty>

          <.command_group :if={@matches != []}>
            <.command_item :for={component <- @matches}>
              <.link navigate={~p"/docs/#{component}"} class="block w-full">
                {Docs.title(component)}
              </.link>
            </.command_item>
          </.command_group>
        </.command_list>
      </.command>
    </.dialog>
    """
  end

  # The dialog's own opener, so the palette costs no round trip to appear.
  defp open(id), do: LiveBase.Dialog.open(id)
end

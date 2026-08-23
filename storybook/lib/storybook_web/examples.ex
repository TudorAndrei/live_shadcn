defmodule StorybookWeb.Examples do
  @moduledoc """
  The examples every generated component is shown and verified with.

  Each example is what a person would actually type. That is the point: if the
  markup here is awkward, the generated API is awkward, and no amount of correct
  output makes up for that.

  `mix ui.verify` drives these same pages in a browser, so an example is both
  the demonstration and the fixture.
  """

  use StorybookWeb, :html

  import LiveShadcn.UI.Accordion
  import LiveShadcn.UI.Alert
  import LiveShadcn.UI.AlertDialog
  import LiveShadcn.UI.AspectRatio
  import LiveShadcn.UI.Attachment
  import LiveShadcn.UI.Avatar
  import LiveShadcn.UI.Badge
  import LiveShadcn.UI.Bubble
  import LiveShadcn.UI.ButtonGroup
  import LiveShadcn.UI.Item
  import LiveShadcn.UI.Marker
  import LiveShadcn.UI.Message
  import LiveShadcn.UI.NavigationMenu
  import LiveShadcn.UI.Pagination
  import LiveShadcn.UI.Popover
  import LiveShadcn.UI.Tooltip
  import LiveShadcn.UI.Breadcrumb
  import LiveShadcn.UI.Button
  import LiveShadcn.UI.Card
  import LiveShadcn.UI.Checkbox
  import LiveShadcn.UI.Collapsible
  import LiveShadcn.UI.Combobox
  import LiveShadcn.UI.ContextMenu
  import LiveShadcn.UI.Dialog
  import LiveShadcn.UI.DropdownMenu
  import LiveShadcn.UI.Input
  import LiveShadcn.UI.Label
  import LiveShadcn.UI.Switch
  import LiveShadcn.UI.Textarea
  import LiveShadcn.UI.Toggle
  import LiveShadcn.UI.Empty
  import LiveShadcn.UI.HoverCard
  import LiveShadcn.UI.Kbd
  import LiveShadcn.UI.Progress
  import LiveShadcn.UI.RadioGroup
  import LiveShadcn.UI.Select
  import LiveShadcn.UI.Separator
  import LiveShadcn.UI.Sheet
  import LiveShadcn.UI.Skeleton
  import LiveShadcn.UI.Spinner
  import LiveShadcn.UI.Table
  import LiveShadcn.UI.Tabs

  @doc "Every component that has examples, in the order they are listed."
  def components do
    ~w(accordion alert alert-dialog aspect-ratio attachment avatar badge breadcrumb bubble button
       button-group card checkbox collapsible combobox context-menu dialog dropdown-menu empty hover-card input item kbd label marker message
       navigation-menu pagination popover progress radio-group select separator sheet skeleton spinner switch table tabs textarea toggle tooltip)
  end

  @doc "The examples for a component."
  def all("accordion") do
    [
      %{
        id: "default",
        title: "One panel at a time",
        description: "The Base UI default: opening a panel closes the one before it.",
        render: &accordion_default/1
      },
      %{
        id: "multiple",
        title: "Several panels at once",
        description: "`multiple` leaves the other panels alone.",
        render: &accordion_multiple/1
      },
      %{
        id: "states",
        title: "Open and disabled",
        description: "An item can start open, and an item can refuse interaction.",
        render: &accordion_states/1
      }
    ]
  end

  def all("alert") do
    [one("default", "A message about the page", "Its title, body, and action.", &alert_default/1)]
  end

  def all("alert-dialog") do
    [
      one(
        "default",
        "An interruption",
        "It cannot be dismissed by accident.",
        &alert_dialog_default/1
      )
    ]
  end

  def all("aspect-ratio") do
    [one("default", "Sixteen by nine", "A box that keeps its ratio.", &aspect_ratio_default/1)]
  end

  def all("attachment") do
    [one("default", "A file", "Media, title, description, and an action.", &attachment_default/1)]
  end

  def all("avatar") do
    [one("default", "A person", "An image, and the initials behind it.", &avatar_default/1)]
  end

  def all("bubble") do
    [one("default", "A conversation", "Two turns, aligned to their side.", &bubble_default/1)]
  end

  def all("button-group") do
    [
      one(
        "default",
        "Buttons together",
        "Joined, with a separator between.",
        &button_group_default/1
      )
    ]
  end

  def all("item") do
    [one("default", "A row", "Media, content, and actions on one line.", &item_default/1)]
  end

  def all("marker") do
    [one("default", "A marker", "An icon beside its content.", &marker_default/1)]
  end

  def all("message") do
    [one("default", "A message", "An avatar, a header, and the body.", &message_default/1)]
  end

  def all("pagination") do
    [one("default", "Pages", "Previous, three pages, and next.", &pagination_default/1)]
  end

  def all("badge") do
    [one("variants", "Every variant", "The `cva` table, rendered.", &badge_variants/1)]
  end

  def all("breadcrumb") do
    [one("default", "A trail", "The current page is not a link.", &breadcrumb_default/1)]
  end

  def all("button") do
    [
      one(
        "variants",
        "Every variant",
        "One button per variant in the table.",
        &button_variants/1
      ),
      one("sizes", "Every size", "One button per size in the table.", &button_sizes/1)
    ]
  end

  def all("checkbox") do
    [one("default", "A checkbox", "On, off, and refusing to be either.", &checkbox_default/1)]
  end

  def all("hover-card") do
    [
      one(
        "default",
        "On hover",
        "A card beside a link, positioned the same way.",
        &hover_card_default/1
      )
    ]
  end

  def all("input") do
    [one("default", "A text field", "With a label and an error beside it.", &input_default/1)]
  end

  def all("label") do
    [one("default", "A label", "Naming the control it points at.", &label_default/1)]
  end

  def all("switch") do
    [
      one(
        "default",
        "A switch",
        "The same contract as a checkbox, drawn differently.",
        &switch_default/1
      )
    ]
  end

  def all("tabs") do
    [one("default", "One panel at a time", "Arrow keys walk the row.", &tabs_default/1)]
  end

  def all("textarea") do
    [one("default", "A longer field", "For text that runs on.", &textarea_default/1)]
  end

  def all("toggle") do
    [one("default", "A pressed button", "On or off, and it says which.", &toggle_default/1)]
  end

  def all("tooltip") do
    [
      one(
        "default",
        "A hint",
        "The same positioning, without taking the focus.",
        &tooltip_default/1
      )
    ]
  end

  def all("card") do
    [one("default", "A card", "Header, content, and footer.", &card_default/1)]
  end

  def all("collapsible") do
    [
      one(
        "default",
        "One panel",
        "The same recipe as the accordion, with one item.",
        &collapsible_default/1
      )
    ]
  end

  def all("combobox") do
    [
      one(
        "default",
        "A list with a value",
        "The listbox recipe, with a text field.",
        &combobox_default/1
      )
    ]
  end

  def all("context-menu") do
    [
      one(
        "default",
        "The same menu, elsewhere",
        "One recipe, two components.",
        &context_menu_default/1
      )
    ]
  end

  def all("navigation-menu") do
    [
      one(
        "default",
        "Links in a menu",
        "The menu recipe with navigation in it.",
        &navigation_menu_default/1
      )
    ]
  end

  def all("dialog") do
    [
      one(
        "default",
        "A dialog",
        "Opens over the page and takes the focus with it.",
        &dialog_default/1
      )
    ]
  end

  def all("dropdown-menu") do
    [
      one(
        "default",
        "A list of actions",
        "Arrow keys move a highlight, not the focus.",
        &dropdown_menu_default/1
      )
    ]
  end

  def all("empty") do
    [
      one(
        "default",
        "Nothing here yet",
        "What a list says when it has no rows.",
        &empty_default/1
      )
    ]
  end

  def all("kbd") do
    [one("default", "A shortcut", "Keys, grouped.", &kbd_default/1)]
  end

  def all("popover") do
    [one("default", "Beside its trigger", "It lands where there is room.", &popover_default/1)]
  end

  def all("progress") do
    [
      one(
        "default",
        "Part of the way",
        "Track, indicator, label, and value.",
        &progress_default/1
      )
    ]
  end

  def all("radio-group") do
    [one("default", "One of three", "Choosing one unchooses the others.", &radio_group_default/1)]
  end

  def all("select") do
    [one("default", "One of a list", "The trigger reads what was chosen.", &select_default/1)]
  end

  def all("separator") do
    [one("default", "A rule", "Between two pieces of text.", &separator_default/1)]
  end

  def all("sheet") do
    [one("default", "From the side", "The same recipe, arriving from an edge.", &sheet_default/1)]
  end

  def all("skeleton") do
    [one("default", "Loading", "The shape of what is coming.", &skeleton_default/1)]
  end

  def all("spinner") do
    [one("default", "Working", "A spinner with a label beside it.", &spinner_default/1)]
  end

  def all("table") do
    [one("default", "Rows", "Caption, header, body, and footer.", &table_default/1)]
  end

  def all(_component), do: []

  defp one(id, title, description, render),
    do: %{id: id, title: title, description: description, render: render}

  @doc "One example, or `:error` when the name is not one of them."
  def fetch(component, id) do
    case Enum.find(all(component), &(&1.id == id)) do
      nil -> :error
      example -> {:ok, example}
    end
  end

  defp accordion_default(assigns) do
    ~H"""
    <.accordion id="faq" class="max-w-80">
      <:item id="faq-what" title="What is Base UI?">
        Base UI is a library of unstyled components for design systems and web apps.
      </:item>
      <:item id="faq-start" title="How do I get started?">
        Read the quick start guide. If you have used unstyled libraries before, you
        will feel at home.
      </:item>
      <:item id="faq-use" title="Can I use it for my project?">
        Of course. Base UI is free and open source.
      </:item>
    </.accordion>
    """
  end

  defp accordion_multiple(assigns) do
    ~H"""
    <.accordion id="release" multiple class="max-w-80">
      <:item id="release-added" title="Added">
        The disclosure recipe, and the accordion generated from it.
      </:item>
      <:item id="release-changed" title="Changed">
        The spec now records what the shadcn style sheets read, not only the
        component source.
      </:item>
    </.accordion>
    """
  end

  defp alert_dialog_default(assigns) do
    ~H"""
    <.alert_dialog id="publish" alert dismissable={false}>
      <:trigger>Publish 0.1.0</:trigger>
      <:title>Publish to hex?</:title>
      <:description>A published version cannot be taken back.</:description>
      <:footer>
        <.button variant="ghost" phx-click={LiveBase.Dialog.close("publish")}>Not yet</.button>
        <.button phx-click={LiveBase.Dialog.close("publish")}>Publish</.button>
      </:footer>
      Every check has to have passed first: `mix ui.verify` on every component.
    </.alert_dialog>
    """
  end

  defp sheet_default(assigns) do
    ~H"""
    <.sheet id="filters">
      <:trigger>Filters</:trigger>
      <:title>Narrow the inventory</:title>
      <:description>By tier, by recipe, or by what the pipeline has reached.</:description>
      <div class="flex flex-col gap-3 text-sm">
        <div class="flex items-center gap-2">
          <.checkbox id="tier-1" name="tier-1" checked aria-labelledby="tier-1-label" />
          <.label id="tier-1-label">Tier 1 only</.label>
        </div>
        <div class="flex items-center gap-2">
          <.checkbox id="verified" name="verified" aria-labelledby="verified-label" />
          <.label id="verified-label">Verified only</.label>
        </div>
      </div>
    </.sheet>
    """
  end

  defp aspect_ratio_default(assigns) do
    ~H"""
    <.aspect_ratio ratio="1.7778" class="bg-muted max-w-sm rounded-md">
      <div class="text-muted-foreground flex h-full items-center justify-center text-sm">
        16 / 9
      </div>
    </.aspect_ratio>
    """
  end

  defp attachment_default(assigns) do
    ~H"""
    <.attachment_group class="max-w-md">
      <.attachment>
        <.attachment_media />
        <.attachment_content>
          <.attachment_title>accordion.json</.attachment_title>
          <.attachment_description>4 KB · spec</.attachment_description>
        </.attachment_content>
      </.attachment>
    </.attachment_group>
    """
  end

  defp avatar_default(assigns) do
    ~H"""
    <.avatar_group>
      <.avatar>
        <.avatar_fallback>BU</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_fallback>SC</.avatar_fallback>
      </.avatar>
      <.avatar_group_count>+3</.avatar_group_count>
    </.avatar_group>
    """
  end

  defp bubble_default(assigns) do
    ~H"""
    <.bubble_group class="max-w-md">
      <.bubble align="start">
        <.bubble_content>Which stage writes the snapshot?</.bubble_content>
      </.bubble>
      <.bubble align="end">
        <.bubble_content>`mix ui.verify`, from the examples.</.bubble_content>
      </.bubble>
    </.bubble_group>
    """
  end

  defp button_group_default(assigns) do
    ~H"""
    <.button_group>
      <.button variant="outline">Fetch</.button>
      <.button_group_separator />
      <.button variant="outline">Generate</.button>
      <.button_group_separator />
      <.button variant="outline">Verify</.button>
    </.button_group>
    """
  end

  defp item_default(assigns) do
    ~H"""
    <%!-- The group carries `role="list"` from upstream, so each item is a
          `listitem`. Upstream leaves that to the caller, and so does this. --%>
    <.item_group class="max-w-md">
      <.item role="listitem">
        <.item_content>
          <.item_title>accordion</.item_title>
          <.item_description>disclosure · tier 1 · verified</.item_description>
        </.item_content>
        <.item_actions>
          <.button size="sm" variant="ghost">Open</.button>
        </.item_actions>
      </.item>
    </.item_group>
    """
  end

  defp marker_default(assigns) do
    ~H"""
    <.marker class="max-w-md">
      <.marker_content>The spec is committed; the sources are not.</.marker_content>
    </.marker>
    """
  end

  defp message_default(assigns) do
    ~H"""
    <.message_group class="max-w-md">
      <.message>
        <.message_content>
          <.message_header>live_shadcn</.message_header>
          Twenty-three components generated, none edited by hand.
        </.message_content>
      </.message>
    </.message_group>
    """
  end

  defp pagination_default(assigns) do
    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous href="#" />
        </.pagination_item>
        <.pagination_item :for={page <- 1..3}>
          <.pagination_link href="#">{page}</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_next href="#" />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  defp alert_default(assigns) do
    ~H"""
    <.alert class="max-w-md">
      <.alert_title>Upstream moved</.alert_title>
      <.alert_description>
        Four class strings changed and one component is new.
      </.alert_description>
      <.alert_action>
        <.button variant="outline" size="sm">Review</.button>
      </.alert_action>
    </.alert>
    """
  end

  defp badge_variants(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.badge :for={variant <- ~w(default secondary outline destructive)} variant={variant}>
        {variant}
      </.badge>
    </div>
    """
  end

  defp breadcrumb_default(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="/">Components</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Accordion</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp button_variants(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.button
        :for={variant <- ~w(default secondary outline ghost destructive link)}
        variant={variant}
      >
        {variant}
      </.button>
    </div>
    """
  end

  defp button_sizes(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.button :for={size <- ~w(xs sm default lg)} size={size}>{size}</.button>
    </div>
    """
  end

  defp checkbox_default(assigns) do
    ~H"""
    <%!-- A `<label for>` names a labelable element, and a `<span role="checkbox">`
          is not one. The control is named by the label it sits beside. --%>
    <div class="flex flex-col gap-3 text-sm">
      <div class="flex items-center gap-2">
        <.checkbox id="subscribe" name="subscribe" checked aria-labelledby="subscribe-label" />
        <.label id="subscribe-label">Send me the sync pull requests</.label>
      </div>
      <div class="flex items-center gap-2">
        <.checkbox id="beta" name="beta" aria-labelledby="beta-label" />
        <.label id="beta-label">Try new recipes first</.label>
      </div>
      <div class="flex items-center gap-2">
        <.checkbox id="locked" name="locked" checked disabled aria-labelledby="locked-label" />
        <.label id="locked-label">Verified components stay verified</.label>
      </div>
    </div>
    """
  end

  defp hover_card_default(assigns) do
    ~H"""
    <.hover_card id="upstream">
      <:trigger>shadcn-ui/ui</:trigger>
      Where the class strings come from. Pinned to a commit, and every file's
      digest recorded, so drift shows up as a diff.
    </.hover_card>
    """
  end

  defp input_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label for="email">Email</.label>
      <.input id="email" name="email" type="email" placeholder="you@example.com" />
    </div>
    """
  end

  defp label_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label for="ref">Upstream ref</.label>
      <.input id="ref" name="ref" value="ac60ef5" readonly />
    </div>
    """
  end

  defp switch_default(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-sm">
      <.switch id="watch" name="watch" checked aria-labelledby="watch-label" />
      <.label id="watch-label">Watch upstream weekly</.label>
    </div>
    """
  end

  defp tabs_default(assigns) do
    ~H"""
    <.tabs id="stages" value="spec" class="max-w-md">
      <:tab value="fetch" label="Fetch">
        Pins each upstream repository to a commit and records a digest per file.
      </:tab>
      <:tab value="spec" label="Spec">
        Reads the component source, the Base UI page, and the style sheets into
        one JSON document.
      </:tab>
      <:tab value="gen" label="Generate">
        Turns that document into a HEEx module. Twice on the same spec gives the
        same bytes.
      </:tab>
    </.tabs>
    """
  end

  defp textarea_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label for="notes">Notes</.label>
      <.textarea id="notes" name="notes" rows="3" placeholder="What changed upstream?" />
    </div>
    """
  end

  defp toggle_default(assigns) do
    ~H"""
    <.toggle id="bold" name="bold" aria-label="Bold">B</.toggle>
    """
  end

  defp card_default(assigns) do
    ~H"""
    <.card class="max-w-sm">
      <.card_header>
        <.card_title>Accordion</.card_title>
        <.card_description>Generated from registry/spec/accordion.json.</.card_description>
      </.card_header>
      <.card_content>
        Every class string came from upstream. Nothing here was typed by a person.
      </.card_content>
      <.card_footer>
        <.button size="sm">Read the spec</.button>
      </.card_footer>
    </.card>
    """
  end

  defp collapsible_default(assigns) do
    ~H"""
    <.collapsible id="more" title="What the pipeline does" class="max-w-80">
      Fetch, spec, generate, verify. Four stages, each one deterministic.
    </.collapsible>
    """
  end

  defp combobox_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label id="recipe-label">Recipe</.label>
      <.combobox id="recipe" name="recipe" labelledby="recipe-label">
        <:option value="disclosure" label="Disclosure" />
        <:option value="dialog" label="Dialog" />
        <:option value="listbox" label="Listbox" />
      </.combobox>
    </div>
    """
  end

  defp context_menu_default(assigns) do
    ~H"""
    <.context_menu id="on-spec">
      <:trigger>accordion.json</:trigger>
      <:item value="regen">Regenerate</:item>
      <:item value="verify">Verify</:item>
    </.context_menu>
    """
  end

  defp navigation_menu_default(assigns) do
    ~H"""
    <.navigation_menu id="docs">
      <:trigger>Documentation</:trigger>
      <p class="p-2 text-sm">
        The roadmap, the inventory, and the architecture.
      </p>
    </.navigation_menu>
    """
  end

  defp dialog_default(assigns) do
    ~H"""
    <.dialog id="confirm">
      <:trigger>Delete the accordion</:trigger>
      <:title>Are you sure?</:title>
      <:description>This removes the component and its spec.</:description>
      The upstream sources stay where they are. Only what the pipeline generated
      is removed, and `mix ui.gen` puts it back.
      <:footer>
        <.button variant="ghost" phx-click={LiveBase.Dialog.close("confirm")}>Cancel</.button>
        <.button variant="destructive">Delete</.button>
      </:footer>
    </.dialog>
    """
  end

  defp dropdown_menu_default(assigns) do
    ~H"""
    <.dropdown_menu id="actions">
      <:trigger>Actions</:trigger>
      <:item value="fetch">Fetch upstream</:item>
      <:item value="generate">Regenerate</:item>
      <:item value="verify">Verify</:item>
      <:item value="publish" disabled>Publish</:item>
    </.dropdown_menu>
    """
  end

  defp empty_default(assigns) do
    ~H"""
    <.empty class="max-w-sm">
      <.empty_header>
        <.empty_title>No components yet</.empty_title>
        <.empty_description>Run `mix ui.gen` to fill the registry.</.empty_description>
      </.empty_header>
      <.empty_content>
        <.button size="sm" variant="outline">Read the roadmap</.button>
      </.empty_content>
    </.empty>
    """
  end

  defp kbd_default(assigns) do
    ~H"""
    <.kbd_group>
      <.kbd>ctrl</.kbd>
      <.kbd>k</.kbd>
    </.kbd_group>
    """
  end

  defp popover_default(assigns) do
    ~H"""
    <.popover id="details">
      <:trigger>What is a recipe?</:trigger>
      <:title>Recipes</:title>
      The one hand-written part of the pipeline. It says which Base UI part plays
      which role, and what expression computes each attribute.
    </.popover>
    """
  end

  defp tooltip_default(assigns) do
    ~H"""
    <.tooltip id="digest" side="top">
      <:trigger>ac60ef5</:trigger>
      The upstream commit every digest in the manifest was taken at.
    </.tooltip>
    """
  end

  defp progress_default(assigns) do
    ~H"""
    <.progress value="62" class="max-w-sm">
      <.progress_label>Generating</.progress_label>
      <.progress_value>62%</.progress_value>
      <.progress_track>
        <.progress_indicator />
      </.progress_track>
    </.progress>
    """
  end

  defp radio_group_default(assigns) do
    ~H"""
    <.radio_group id="style" role="radiogroup" aria-labelledby="style-label" class="max-w-sm">
      <.label id="style-label">Style</.label>
      <div
        :for={{style, index} <- Enum.with_index(~w(vega nova maia))}
        class="flex items-center gap-2 text-sm"
      >
        <.radio_group_item
          id={"style-#{style}"}
          group="style"
          name="style"
          value={style}
          checked={index == 0}
          aria-labelledby={"style-#{style}-label"}
        />
        <.label id={"style-#{style}-label"}>{style}</.label>
      </div>
    </.radio_group>
    """
  end

  defp select_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label id="style-select-label">Style</.label>
      <.select id="style-select" name="style" labelledby="style-select-label">
        <:option value="vega" label="Vega" />
        <:option value="nova" label="Nova" />
        <:option value="maia" label="Maia" />
      </.select>
    </div>
    """
  end

  defp separator_default(assigns) do
    ~H"""
    <div class="max-w-sm text-sm">
      <p>The spec is committed.</p>
      <.separator class="my-4" />
      <p>The upstream sources are not.</p>
    </div>
    """
  end

  defp skeleton_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.skeleton class="h-4 w-3/4" />
      <.skeleton class="h-4 w-1/2" />
      <.skeleton class="h-4 w-2/3" />
    </div>
    """
  end

  defp spinner_default(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-sm">
      <.spinner />
      <span>Verifying</span>
    </div>
    """
  end

  defp table_default(assigns) do
    assigns =
      assign(assigns, :stages, [
        {"ui.fetch", "registry/UPSTREAM.json"},
        {"ui.spec", "registry/spec/*.json"},
        {"ui.gen", "priv/registry/*.ex"},
        {"ui.verify", "registry/VERIFY.json"}
      ])

    ~H"""
    <.table class="max-w-lg">
      <.table_caption>What each pipeline stage leaves behind.</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head>Stage</.table_head>
          <.table_head>Output</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={{stage, output} <- @stages}>
          <.table_cell>{stage}</.table_cell>
          <.table_cell>{output}</.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  defp accordion_states(assigns) do
    ~H"""
    <.accordion id="states" multiple class="max-w-80">
      <:item id="states-open" title="Open on first paint" open>
        The server renders this panel visible, so it is readable before any
        JavaScript has run.
      </:item>
      <:item id="states-disabled" title="Disabled" disabled>
        This panel cannot be opened.
      </:item>
    </.accordion>
    """
  end
end

defmodule StorybookWeb.Examples do
  @moduledoc """
  The examples every reviewed port is shown and verified with.

  Each example is what a person would actually type. That is the point: if the
  markup here is awkward, the port API is awkward, and no amount of correct
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
  import LiveShadcn.UI.Menubar
  import LiveShadcn.UI.Message
  import LiveShadcn.UI.MessageScroller
  import LiveShadcn.UI.NativeSelect
  import LiveShadcn.UI.NavigationMenu
  import LiveShadcn.UI.Pagination
  import LiveShadcn.UI.Popover
  import LiveShadcn.UI.Tooltip
  import LiveShadcn.UI.Breadcrumb
  import LiveShadcn.UI.Button
  import LiveShadcn.UI.Card
  import LiveShadcn.UI.Calendar
  import LiveShadcn.UI.Chart
  import LiveShadcn.UI.Carousel
  import LiveShadcn.UI.Checkbox
  import LiveShadcn.UI.Collapsible
  import LiveShadcn.UI.Combobox
  import LiveShadcn.UI.Command
  import LiveShadcn.UI.ContextMenu
  import LiveShadcn.UI.Dialog
  import LiveShadcn.UI.Drawer
  import LiveShadcn.UI.DropdownMenu
  import LiveShadcn.UI.Input
  import LiveShadcn.UI.InputOtp
  import LiveShadcn.UI.InputGroup
  import LiveShadcn.UI.Label
  import LiveShadcn.UI.Switch
  import LiveShadcn.UI.Textarea
  import LiveShadcn.UI.Toggle
  import LiveShadcn.UI.ToggleGroup
  import LiveShadcn.UI.Empty
  import LiveShadcn.UI.Field
  import LiveShadcn.UI.HoverCard
  import LiveShadcn.UI.Kbd
  import LiveShadcn.UI.Progress
  import LiveShadcn.UI.Questionnaire
  import LiveShadcn.UI.RadioGroup
  import LiveShadcn.UI.Resizable
  import LiveShadcn.UI.ScrollArea
  import LiveShadcn.UI.Select
  import LiveShadcn.UI.Separator
  import LiveShadcn.UI.Sheet
  import LiveShadcn.UI.Sidebar
  import LiveShadcn.UI.Skeleton
  import LiveShadcn.UI.Slider
  alias LiveShadcn.UI.Sonner
  import LiveShadcn.UI.Spinner
  import LiveShadcn.UI.Table
  import LiveShadcn.UI.Tabs
  import LiveShadcn.UI.Toast

  # The AI Elements package ships its components compiled, so they are imported
  # from their own namespace rather than copied in by `mix ui.add`.
  # Aliased, not imported: `LiveShadcn.UI.Message` exports `message/1` too, and
  # two registries having a `message` is the same fact at the Elixir level.
  alias LiveAiElements.Components.Message, as: AiMessage

  # Aliased for the same reason `Message` is: `LiveShadcn.UI.Attachment` exports
  # an `attachment/1` too, and the two registries drawing an attachment is one
  # fact about upstream rather than a collision to rename away.
  alias LiveAiElements.Components.Attachments, as: AiAttachments

  import LiveAiElements.Components.ChainOfThought
  import LiveAiElements.Components.Checkpoint
  import LiveAiElements.Components.Confirmation
  import LiveAiElements.Components.EnvironmentVariables
  import LiveAiElements.Components.Plan
  import LiveAiElements.Components.PackageInfo
  import LiveAiElements.Components.Question
  import LiveAiElements.Components.Reasoning
  import LiveAiElements.Components.Snippet
  import LiveAiElements.Components.Sources
  import LiveAiElements.Components.Suggestion
  import LiveAiElements.Components.Task

  @toasts [
    %{id: "spec", type: "info", title: "Spec written", description: "53 components read."},
    %{id: "gen", type: "success", title: "Generated", description: "Nothing was typed by hand."},
    %{id: "drift", type: "warning", title: "Upstream moved", description: "Two digests changed."}
  ]

  @transcription_segments [
    %{start_second: 0.119, end_second: 0.219, text: "You"},
    %{start_second: 0.259, end_second: 0.439, text: "can"},
    %{start_second: 0.459, end_second: 0.699, text: "build"},
    %{start_second: 0.72, end_second: 0.799, text: "and"},
    %{start_second: 0.879, end_second: 1.339, text: "host"},
    %{start_second: 1.36, end_second: 1.539, text: "many"},
    %{start_second: 1.6, end_second: 1.86, text: "different"},
    %{start_second: 1.899, end_second: 2.099, text: "types"},
    %{start_second: 2.119, end_second: 2.2, text: "of"},
    %{start_second: 2.259, end_second: 2.96, text: "applications"},
    %{start_second: 3.48, end_second: 3.699, text: "from"},
    %{start_second: 3.779, end_second: 4.099, text: "static"},
    %{start_second: 4.179, end_second: 4.519, text: "sites"},
    %{start_second: 4.539, end_second: 4.759, text: "with"},
    %{start_second: 4.799, end_second: 4.939, text: "your"},
    %{start_second: 4.96, end_second: 5.219, text: "favorite"},
    %{start_second: 5.319, end_second: 5.939, text: "framework,"},
    %{start_second: 5.96, end_second: 6.519, text: "multi-tenant"},
    %{start_second: 6.559, end_second: 7.259, text: "applications"},
    %{start_second: 7.699, end_second: 7.759, text: "or"},
    %{start_second: 7.859, end_second: 8.739, text: "micro-frontends"},
    %{start_second: 8.78, end_second: 8.96, text: "to"},
    %{start_second: 9.099, end_second: 9.779, text: "AI-powered"},
    %{start_second: 9.82, end_second: 10.439, text: "agents."}
  ]

  @doc """
  The toasts a page starts with.

  The toaster takes its list from an assign, because the server owns it — that
  is the component's whole design. So the page showing it has to own one too:
  an example that held the list in its own markup would be demonstrating
  something the component does not do.
  """
  def toasts, do: @toasts

  @doc """
  What a page assigns before it renders an example.

  Three places render one — the index, the preview, and `mix snapshot` — and an
  example that reads an assign has to find it in all three.

  `show_values` is the environment variables example's, and it is an assign for
  the reason that component exists: the value it reveals is a secret, so the
  server decides when the page is given it.
  """
  def page_assigns, do: %{toasts: @toasts, show_values: false}

  @doc "The list with one toast gone, given the id the component pushed back."
  def dismiss(toasts, toaster, id),
    do: Enum.reject(toasts, &(LiveBase.Toast.toast_id(toaster, &1.id) == id))

  @doc "Every component that has examples, in the order they are listed."
  def components do
    ~w(accordion alert alert-dialog aspect-ratio attachment avatar badge breadcrumb bubble button calendar carousel
       button-group card chart checkbox collapsible combobox command context-menu dialog drawer dropdown-menu empty hover-card input item kbd label marker menubar
       input-group input-otp message-scroller native-select navigation-menu pagination popover progress radio-group resizable scroll-area select separator sheet skeleton slider spinner switch table tabs task sources suggestion checkpoint confirmation chain-of-thought reasoning package-info field textarea toggle tooltip
       toggle-group question questionnaire sidebar snippet sonner toast shadcn-message ai_elements-message
       artifact attachments commit environment-variables image mic-selector model-selector plan
       queue speech-input transcription voice-selector
       inline-citation stack-trace test-results tool web-preview
       agent audio-player code-block context conversation file-tree prompt-input
       sandbox schema-display shimmer terminal
       connection controls edge jsx-preview node panel persona toolbar
       open-in-chat)
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

  def all("carousel") do
    [
      one(
        "default",
        "Three updates",
        "Scroll, arrow keys, or the controls move one slide.",
        &carousel_default/1
      )
    ]
  end

  def all("calendar") do
    [one("default", "April 2026", "A server-computed month grid.", &calendar_default/1)]
  end

  def all("chart") do
    [one("default", "Plot slot", "Chart chrome around caller-owned data.", &chart_default/1)]
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

  # Named by its source as well as its name: AI Elements has a `message` too,
  # and an example named after the name alone would belong to neither. The
  # separator is a dash rather than a slash because this name is a URL segment
  # and a file name as well as a key.
  def all("shadcn-message") do
    [one("default", "A message", "An avatar, a header, and the body.", &message_default/1)]
  end

  def all("ai_elements-message") do
    [
      one(
        "default",
        "A turn in a conversation",
        "The assistant's side, with the answer inside it.",
        &ai_message_default/1
      )
    ]
  end

  def all("drawer") do
    [
      one(
        "default",
        "A sheet from the edge",
        "The same dialog contract, with a handle a finger would push.",
        &drawer_default/1
      )
    ]
  end

  def all("menubar") do
    [
      one(
        "default",
        "A bar of menus",
        "The bar is this component; each menu inside it is a dropdown menu.",
        &menubar_default/1
      )
    ]
  end

  def all("input-group") do
    [
      one(
        "default",
        "A field with something beside it",
        "An addon on each side of the input, sharing one box.",
        &input_group_default/1
      )
    ]
  end

  def all("input-otp") do
    [one("default", "Verification code", "A six-digit code field.", &input_otp_default/1)]
  end

  def all("native-select") do
    [
      one(
        "default",
        "The platform's own",
        "A `<select>`, with the arrow the platform draws covered by shadcn's.",
        &native_select_default/1
      )
    ]
  end

  def all("command") do
    [one("default", "Commands", "A visible command list.", &command_default/1)]
  end

  def all("scroll-area") do
    [
      one(
        "default",
        "A box that scrolls",
        "The scrollbar is drawn rather than the platform's, and measured in the browser.",
        &scroll_area_default/1
      )
    ]
  end

  def all("message-scroller") do
    [
      one(
        "default",
        "A message stream",
        "A native viewport for a growing conversation.",
        &message_scroller_default/1
      )
    ]
  end

  def all("slider") do
    [
      one(
        "default",
        "One value",
        "A thumb the platform draws under one it does not.",
        &slider_default/1
      ),
      one(
        "range",
        "Two values",
        "Two inputs under one name, which a form reports as a list.",
        &slider_range/1
      )
    ]
  end

  def all("toast") do
    [
      one(
        "default",
        "A stack of messages",
        "The list is the server's. Closing one is an event; only the stacking is measured.",
        &toast_default/1
      )
    ]
  end

  def all("sonner") do
    [
      one(
        "default",
        "Server-owned notifications",
        "A server list with Sonner styling.",
        &sonner_default/1
      )
    ]
  end

  def all("sidebar") do
    [
      one(
        "default",
        "Navigation that collapses",
        "A trigger and a rail, both flipping one attribute the class strings read.",
        &sidebar_default/1
      )
    ]
  end

  def all("question") do
    [
      one(
        "default",
        "Asking the reader",
        "A prompt, the options, and a box for anything the options do not cover.",
        &question_default/1
      )
    ]
  end

  def all("questionnaire") do
    [
      one(
        "default",
        "One answer at a time",
        "A prompt with choices and a server-owned next action.",
        &questionnaire_default/1
      )
    ]
  end

  def all("snippet") do
    [
      one(
        "default",
        "A command to copy",
        "The prompt, the command, and the button.",
        &snippet_default/1
      )
    ]
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

  def all("toggle-group") do
    [
      one(
        "default",
        "Text formatting",
        "A row of independent pressed buttons.",
        &toggle_group_default/1
      )
    ]
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

  def all("task") do
    [
      one(
        "default",
        "A step the model reports",
        "AI Elements builds this out of shadcn's collapsible, so the disclosure " <>
          "recipe generates it and the panel opens with no round trip.",
        &task_default/1
      )
    ]
  end

  def all("commit") do
    [
      one(
        "default",
        "One commit, read back",
        "Upstream wraps this in a collapsible; those parts are the " <>
          "application's own, and what the package writes is the row.",
        &commit_default/1
      )
    ]
  end

  def all("image") do
    [
      one(
        "default",
        "What the model drew",
        "Base64 in, an `<img>` out. The `alt` is read off the rest object " <>
          "upstream, and it is an attribute here.",
        &image_default/1
      )
    ]
  end

  def all("model-selector") do
    [
      one(
        "default",
        "A model, named",
        "The command dialog is composed, not generated: these are the parts " <>
          "that are this component's own.",
        &model_selector_default/1
      )
    ]
  end

  def all("queue") do
    [
      one(
        "default",
        "What is waiting",
        "Two items, one done. `completed` is an attribute per part, because " <>
          "React reads it off a context and HEEx has none.",
        &queue_default/1
      )
    ]
  end

  def all("speech-input") do
    [
      one(
        "default",
        "A microphone that waits",
        "Listening is the browser's — `SpeechRecognition`, or a recorder " <>
          "where there is none — so whether it is listening is an attribute " <>
          "the caller sets, and the three pulses follow it.",
        &speech_input_default/1
      )
    ]
  end

  def all("transcription") do
    [
      one(
        "default",
        "What was said, and when",
        "Every segment is a button that seeks. Upstream asks whether a seek " <>
          "handler was passed; here a caller binds `phx-click` and it is.",
        &transcription_default/1
      )
    ]
  end

  def all("voice-selector") do
    [
      one(
        "default",
        "One voice, described",
        "Filed as a listbox and it is not one: eleven of its parts wrap a " <>
          "command dialog, and these eight are its own.",
        &voice_selector_default/1
      )
    ]
  end

  # The seven React Flow files that are markup, and the two beside them.
  #
  # `canvas` is not here. It is `<ReactFlow>` with a `<Background>` inside it —
  # the graph engine rather than a skin over one — and `registry/INVENTORY.json`
  # marks it `unsupported`. `ROADMAP.md` names the hex package to reach for.
  # The other six are a box and a class string, or the arithmetic of a wire.

  def all("open-in-chat") do
    [
      one(
        "default",
        "The same question, somewhere else",
        "Twelve wrappers around a dropdown menu, and six of them are links " <>
          "with a logo, a title and a query string. `asChild` says the item " <>
          "*is* the link, so the link is what the component draws.",
        &open_in_chat_default/1
      )
    ]
  end

  def all("connection") do
    [
      one(
        "default",
        "The wire being dragged",
        "Four numbers and a bezier. Upstream computes the path in a template " <>
          "literal, and so does this.",
        &connection_default/1
      )
    ]
  end

  def all("controls") do
    [
      one(
        "default",
        "The buttons that zoom a graph",
        "A box with a class string, which is the whole of what AI Elements " <>
          "adds to React Flow's own control bar.",
        &controls_default/1
      )
    ]
  end

  def all("edge") do
    [
      one(
        "default",
        "A line between two nodes",
        "The path is React Flow's arithmetic over where the nodes ended up, " <>
          "so it is an attribute here — the same answer `code-block` gives " <>
          "about its tokens.",
        &edge_default/1
      ),
      one(
        "animated",
        "An animated connection",
        "The caller can style the path while a marker moves along it.",
        &edge_animated/1
      )
    ]
  end

  def all("jsx-preview") do
    [
      one(
        "default",
        "Markup a model wrote",
        "Upstream compiles a string of JSX at render. A server cannot, and a " <>
          "template language that drew markup from a string would be the " <>
          "injection this pipeline is built to avoid — so what goes there is " <>
          "the caller's.",
        &jsx_preview_default/1
      )
    ]
  end

  def all("node") do
    [
      one(
        "default",
        "A box on the graph",
        "shadcn's card, with the class strings AI Elements writes over it and " <>
          "a handle at either side.",
        &node_default/1
      )
    ]
  end

  def all("panel") do
    [
      one(
        "default",
        "A box that floats over the graph",
        "Where it floats is React Flow's; the box is the component.",
        &panel_default/1
      )
    ]
  end

  def all("persona") do
    [
      one(
        "default",
        "The canvas a face is painted into",
        "One element, and the Rive runtime that paints it is the " <>
          "application's — the same arrangement media-chrome gets.",
        &persona_default/1
      )
    ]
  end

  def all("toolbar") do
    [
      one(
        "default",
        "The row of actions on a node",
        "React Flow puts it under the node it belongs to. The row is the " <>
          "component.",
        &toolbar_default/1
      )
    ]
  end

  def all("agent") do
    [
      one(
        "default",
        "A model, and what it may reach for",
        "The output is a code block, which is why neither generated until the " <>
          "other did.",
        &agent_default/1
      )
    ]
  end

  def all("audio-player") do
    [
      one(
        "default",
        "A player made of custom elements",
        "media-chrome is a set of custom elements, and its React package " <>
          "renders them. A HEEx template writes the same tags, and the " <>
          "browser upgrades them once the application loads the library.",
        &audio_player_default/1
      )
    ]
  end

  def all("code-block") do
    [
      one(
        "default",
        "Code, in the state upstream draws first",
        "shiki tokenises in the browser, so upstream draws one token per line " <>
          "until it has loaded. That is what a server can draw, and the " <>
          "tokens are the caller's to supply.",
        &code_block_default/1
      )
    ]
  end

  def all("context") do
    [
      one(
        "default",
        "What a window has been spent on",
        "`Intl.NumberFormat` writes `1.2K` and `$0.02`; the module carries " <>
          "the two functions that write the same, because Elixir's standard " <>
          "library has neither.",
        &context_default/1
      )
    ]
  end

  def all("conversation") do
    [
      one(
        "default",
        "A log that stays at the bottom",
        "Upstream sticks to the bottom with `use-stick-to-bottom`; here the " <>
          "scroller recipe places `LiveBase.Scroller`, which is the same job " <>
          "and the same measurements.",
        &conversation_default/1
      )
    ]
  end

  def all("prompt-input") do
    [
      one(
        "default",
        "The box a question is typed into",
        "Twenty-two of its thirty-five parts wrap a menu, a select, a hover " <>
          "card or a command palette, and each of those is one function here. " <>
          "These thirteen are its own.",
        &prompt_input_default/1
      )
    ]
  end

  def all("sandbox") do
    [
      one(
        "default",
        "The one part that is its own",
        "Every other part wraps a collapsible, so the moduledoc says to " <>
          "compose `<.collapsible>` and this is what is left.",
        &sandbox_default/1
      )
    ]
  end

  def all("file-tree") do
    [
      one(
        "default",
        "A folder, open, with a file in it",
        ~S|`role="tree"` is upstream's and so is `role="treeitem"`; the | <>
          "port adds the groups that contract needs and takes the unnamed " <>
          "chevron out of the accessibility tree.",
        &file_tree_default/1
      )
    ]
  end

  def all("schema-display") do
    [
      one(
        "default",
        "One endpoint, described",
        "`dangerouslySetInnerHTML` is read as what it means — the element's " <>
          "children — because HEEx has no door for a string of markup.",
        &schema_display_default/1
      )
    ]
  end

  def all("terminal") do
    [
      one(
        "default",
        "What a command printed",
        "The escape codes a program writes for colour are a job Elixir " <>
          "already does, so the component names the seam and the application " <>
          "chooses what sits behind it.",
        &terminal_default/1
      )
    ]
  end

  def all("shimmer") do
    [
      one(
        "default",
        "A line still being written",
        "Upstream animates `background-position` with `motion`, which calls " <>
          "the Web Animations API. `LiveBase.Shimmer` calls it too, with the " <>
          "same two keyframes read off `initial` and `animate`.",
        &shimmer_default/1
      )
    ]
  end

  def all("inline-citation") do
    [
      one(
        "default",
        "A sentence, and where it came from",
        "The source is a card the reader hovers, so it is drawn where a hover " <>
          "card draws it and this example shows the citation and the source " <>
          "side by side instead.",
        &inline_citation_default/1
      ),
      one(
        "carousel",
        "More than one source",
        "The same carousel controls and index as the official example.",
        &inline_citation_carousel/1
      )
    ]
  end

  def all("stack-trace") do
    [
      one(
        "default",
        "An error, and where it came from",
        "The fourth component built on the clipboard recipe: one button whose " <>
          "state the client owns, and the trace it copies comes from the caller.",
        &stack_trace_default/1
      )
    ]
  end

  def all("test-results") do
    [
      one(
        "default",
        "What passed and what did not",
        "The duration is upstream's own arithmetic, ported: seconds to two " <>
          "decimal places, and a percentage with none.",
        &test_results_default/1
      )
    ]
  end

  def all("tool") do
    [
      one(
        "default",
        "A tool call, with its state",
        "One badge per state, chosen by the attribute. Opening the panel is a " <>
          "disclosure, so it runs on the client.",
        &tool_default/1
      )
    ]
  end

  def all("web-preview") do
    [
      one(
        "default",
        "A frame with an address bar",
        "The frame is empty on purpose: a preview that fetched a page would " <>
          "make the pixel check depend on a network.",
        &web_preview_default/1
      )
    ]
  end

  def all("artifact") do
    [
      one(
        "default",
        "Something the model made",
        "Filed as a disclosure for a year, and it has no trigger: it is a " <>
          "panel with a header, and re-filing it is the whole of the change.",
        &artifact_default/1
      )
    ]
  end

  def all("mic-selector") do
    [
      one(
        "default",
        "Which microphone",
        "The first AI Elements component the corrected shadcn specs unblocked: " <>
          "it folds `command` into a popover and comes out a listbox, with no " <>
          "work of its own.",
        &mic_selector_default/1
      )
    ]
  end

  def all("plan") do
    [
      one(
        "default",
        "A plan the model is working through",
        "A card that opens, which is shadcn's collapsible folded into shadcn's " <>
          "card. `asChild` is what says those are one element and not two.",
        &plan_default/1
      )
    ]
  end

  def all("attachments") do
    [
      one(
        "default",
        "What was attached",
        nil,
        &attachments_default/1
      )
    ]
  end

  def all("environment-variables") do
    [
      one(
        "default",
        "Variables, and the secret one",
        "The switch asks the server, because what it reveals is a secret: a " <>
          "value the page was never given cannot be read out of the page.",
        &environment_variables_default/1
      )
    ]
  end

  def all("checkpoint") do
    [
      one(
        "default",
        "A point a turn can go back to",
        "A label with a rule running off it.",
        &checkpoint_default/1
      )
    ]
  end

  def all("field") do
    [one("default", "A form row", "A label, a control, and the note under it.", &field_default/1)]
  end

  def all("package-info") do
    [
      one(
        "default",
        "A dependency the model changed",
        "The icon comes out of a table keyed by the kind of change.",
        &package_info_default/1
      )
    ]
  end

  def all("chain-of-thought") do
    [
      one(
        "default",
        "How the model got there",
        "The steps behind an answer, folded away until a reader asks.",
        &chain_of_thought_default/1
      )
    ]
  end

  def all("confirmation") do
    [
      one(
        "default",
        "A question the model has to have answered",
        "The body of a tool call waiting on a person.",
        &confirmation_default/1
      )
    ]
  end

  def all("reasoning") do
    [
      one(
        "default",
        "What the model was thinking",
        "The panel renders markdown through the seam, so the renderer is the application's choice.",
        &reasoning_default/1
      )
    ]
  end

  def all("sources") do
    [
      one(
        "default",
        "What the answer was drawn from",
        "The citations a turn produced, folded away until a reader asks.",
        &sources_default/1
      )
    ]
  end

  def all("suggestion") do
    [
      one(
        "default",
        "What to ask next",
        "A row of buttons that scrolls sideways, built on shadcn's button and scroll area.",
        &suggestion_default/1
      )
    ]
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
        "Basic",
        "The pinned official basic dropdown menu example.",
        &dropdown_menu_default/1
      ),
      one(
        "checkboxes",
        "Checkboxes",
        "The pinned official checkbox item example.",
        &dropdown_menu_checkboxes/1
      ),
      one(
        "radio-group",
        "Radio group",
        "The pinned official radio group example.",
        &dropdown_menu_radio_group/1
      ),
      one(
        "complex",
        "Complex",
        "Submenus, shortcuts, disabled items, and grouped actions.",
        &dropdown_menu_complex/1
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

  def all("resizable") do
    [
      one(
        "default",
        "Two panels",
        "Drag the separator to change their width.",
        &resizable_default/1
      )
    ]
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
        The disclosure contract, and the accordion reviewed against it.
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
      Every check has to have passed first: <code>mix ui.verify</code>
      on every component.
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

  defp carousel_default(assigns) do
    ~H"""
    <.carousel id="updates" aria-label="Recent updates" class="mx-12 max-w-md">
      <.carousel_content>
        <.carousel_item :for={update <- ["Spec", "Generator", "Browser"]}>
          <div class="border bg-card p-6 text-card-foreground shadow-sm">
            <p class="font-medium">{update}</p>
            <p class="mt-1 text-sm text-muted-foreground">
              One component state, owned in the right place.
            </p>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  defp calendar_default(assigns) do
    ~H"""
    <.calendar
      id="calendar-default"
      month={~D[2026-04-01]}
      selected={~D[2026-04-15]}
      locale="browser"
      class="max-w-md"
    />
    """
  end

  defp chart_default(assigns) do
    ~H"""
    <.chart_container id="visits" config={%{visits: %{color: "var(--chart-1)"}}} class="max-w-md">
      <svg viewBox="0 0 320 160" role="img" aria-label="Visits increased">
        <path
          d="M0 140 L80 110 L160 120 L240 60 L320 20"
          fill="none"
          stroke="var(--color-visits)"
          stroke-width="8"
        />
      </svg>
    </.chart_container>
    """
  end

  defp command_default(assigns) do
    ~H"""
    <.command class="max-w-md border">
      <.command_input
        placeholder="Search commands"
        aria-label="Search commands"
        controls="commands-list"
      />
      <.command_list id="commands-list">
        <.command_group>
          <.command_item data-selected="true">New file</.command_item>
          <.command_item>Open project</.command_item>
        </.command_group>
        <.command_separator />
        <.command_group>
          <.command_item>
            Settings
            <.command_shortcut>⌘,</.command_shortcut>
          </.command_item>
        </.command_group>
      </.command_list>
    </.command>
    """
  end

  defp input_otp_default(assigns) do
    ~H"""
    <.input_otp
      id="verification-code"
      name="verification_code"
      value="123456"
      maxlength="6"
      aria-label="Verification code"
      class="max-w-48"
    />
    """
  end

  defp message_scroller_default(assigns) do
    ~H"""
    <.message_scroller_provider>
      <.message_scroller class="h-48 max-w-md border">
        <.message_scroller_viewport id="messages-viewport">
          <.message_scroller_content>
            <.message_scroller_item :for={line <- 1..8} class="p-3">
              Message {line}
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  defp sonner_default(assigns) do
    ~H"""
    <Sonner.toaster id="sonner" dismiss="dismiss_toast" duration={0} />
    """
  end

  defp resizable_default(assigns) do
    ~H"""
    <.resizable_panel_group id="resizable-default" class="h-40 max-w-md border">
      <.resizable_panel class="basis-1/2">First panel</.resizable_panel>
      <.resizable_handle with_handle="true" />
      <.resizable_panel class="basis-1/2">Second panel</.resizable_panel>
    </.resizable_panel_group>
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

  defp toggle_group_default(assigns) do
    ~H"""
    <.toggle_group spacing="0" variant="outline" aria-label="Text formatting">
      <:item
        id="bold"
        name="bold"
        checked
        aria-label="Bold"
      >
        B
      </:item>
      <:item
        id="italic"
        name="italic"
        aria-label="Italic"
      >
        I
      </:item>
      <:item
        id="underline"
        name="underline"
        aria-label="Underline"
      >
        U
      </:item>
    </.toggle_group>
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

  defp checkpoint_default(assigns) do
    ~H"""
    <.checkpoint class="max-w-md">
      <.checkpoint_trigger>
        <.checkpoint_icon /> Reverted to the spec before the fold
      </.checkpoint_trigger>
    </.checkpoint>
    """
  end

  defp chain_of_thought_default(assigns) do
    ~H"""
    <.chain_of_thought id="thinking" title="Thought for 4 seconds" class="max-w-80">
      Read the registry index, then the accordion source, then the Base UI page.
    </.chain_of_thought>
    """
  end

  defp confirmation_default(assigns) do
    ~H"""
    <%!-- `approval` and `state` are what upstream draws anything at all for:
    with no approval, or with a tool call still streaming, it renders nothing.
    The reviewed port keeps that guard, so the example is in the state
    the component is about. --%>
    <.confirmation approval="branch" state="approval-requested" class="max-w-md">
      Delete the branch?
    </.confirmation>
    """
  end

  defp reasoning_default(assigns) do
    ~H"""
    <.reasoning
      id="thought"
      title="Thought for 4 seconds"
      class="max-w-80"
      content="The reader wants **today's** weather, so call the tool."
    >
    </.reasoning>
    """
  end

  defp sources_default(assigns) do
    ~H"""
    <div style="height: 110px;">
      <.sources id="citations" title={nil} count={3}>
        <.source href="https://stripe.com/docs/api" title="Stripe API Documentation" />
        <.source href="https://docs.github.com/en/rest" title="GitHub REST API" />
        <.source
          href="https://docs.aws.amazon.com/sdk-for-javascript/"
          title="AWS SDK for JavaScript"
        />
      </.sources>
    </div>
    """
  end

  defp suggestion_default(assigns) do
    ~H"""
    <.suggestions class="max-w-md">
      <.suggestion>What does mix ui.spec read?</.suggestion>
      <.suggestion>Why four hooks?</.suggestion>
      <.suggestion>Show me the accordion</.suggestion>
    </.suggestions>
    """
  end

  defp task_default(assigns) do
    ~H"""
    <.task id="search" title="Searched the registry" class="max-w-80">
      Read 62 component sources and 41 Base UI pages.
    </.task>
    """
  end

  # A one-pixel PNG, so both sides draw the same picture without asking a
  # network for it.
  @png "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

  defp image_default(assigns) do
    assigns = assign(assigns, base64: @png)

    ~H"""
    <LiveAiElements.Components.Image.image
      base64={@base64}
      media_type="image/png"
      alt="A pixel the model drew"
      class="size-24"
    />
    """
  end

  defp commit_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Commit.commit_info class="max-w-md">
      <LiveAiElements.Components.Commit.commit_hash hash="a99f1b7" />
      <LiveAiElements.Components.Commit.commit_message>
        the recipe three components are built on
      </LiveAiElements.Components.Commit.commit_message>
      <LiveAiElements.Components.Commit.commit_metadata>
        <LiveAiElements.Components.Commit.commit_author>
          <LiveAiElements.Components.Commit.commit_author_avatar initials="TA" />
        </LiveAiElements.Components.Commit.commit_author>
        <LiveAiElements.Components.Commit.commit_separator />
        <LiveAiElements.Components.Commit.commit_timestamp
          date="2026-08-26T00:50:00Z"
          formatted="2 hours ago"
        />
      </LiveAiElements.Components.Commit.commit_metadata>
      <LiveAiElements.Components.Commit.commit_actions>
        <LiveAiElements.Components.Commit.commit_copy_button
          id="copy-hash"
          hash="a99f1b7"
          aria-label="Copy the hash"
        />
      </LiveAiElements.Components.Commit.commit_actions>
    </LiveAiElements.Components.Commit.commit_info>
    """
  end

  defp model_selector_default(assigns) do
    ~H"""
    <div class="flex max-w-sm items-center gap-2">
      <LiveAiElements.Components.ModelSelector.model_selector_logo_group />
      <LiveAiElements.Components.ModelSelector.model_selector_name>
        Claude Opus 4.5
      </LiveAiElements.Components.ModelSelector.model_selector_name>
    </div>
    """
  end

  defp queue_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Queue.queue class="max-w-md">
      <LiveAiElements.Components.Queue.queue_section_label label="Waiting" />
      <LiveAiElements.Components.Queue.queue_list>
        <LiveAiElements.Components.Queue.queue_item>
          <LiveAiElements.Components.Queue.queue_item_indicator completed />
          <LiveAiElements.Components.Queue.queue_item_content completed>
            Read every AI Elements spec again
          </LiveAiElements.Components.Queue.queue_item_content>
        </LiveAiElements.Components.Queue.queue_item>
        <LiveAiElements.Components.Queue.queue_item>
          <LiveAiElements.Components.Queue.queue_item_indicator />
          <LiveAiElements.Components.Queue.queue_item_content>
            Write a React reference for each one
          </LiveAiElements.Components.Queue.queue_item_content>
        </LiveAiElements.Components.Queue.queue_item>
      </LiveAiElements.Components.Queue.queue_list>
    </LiveAiElements.Components.Queue.queue>
    """
  end

  defp speech_input_default(assigns) do
    ~H"""
    <div data-speech-example class="flex size-full flex-col items-center justify-center gap-4">
      <div class="flex gap-2">
        <LiveAiElements.Components.SpeechInput.speech_input
          id="dictation"
          aria-label="Start dictation"
          size="icon"
          variant="outline"
        />
        <button
          data-speech-clear
          hidden
          class="text-muted-foreground text-sm underline hover:text-foreground"
          type="button"
        >
          Clear
        </button>
      </div>
      <div data-speech-transcript-card hidden class="max-w-md rounded-lg border bg-card p-4 text-sm">
        <p class="text-muted-foreground"><strong>Transcript:</strong></p>
        <p data-speech-transcript class="mt-2"></p>
      </div>
      <p data-speech-empty class="text-muted-foreground text-sm">
        Click the microphone to start speaking
      </p>
    </div>
    """
  end

  defp transcription_default(assigns) do
    assigns = assign(assigns, :segments, @transcription_segments)

    ~H"""
    <div class="space-y-6 p-6">
      <audio
        id="transcription-audio"
        aria-describedby="transcription-copy"
        controls
        preload="metadata"
      >
        <source
          src="https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/ElevenLabs_2025-11-10T22_10_24_Hayden_pvc_sp110_s50_sb75_se0_b_m2.mp3"
          type="audio/mpeg"
        />
      </audio>
      <LiveAiElements.Components.Transcription.transcription
        id="transcription-copy"
        media_id="transcription-audio"
      >
        <LiveAiElements.Components.Transcription.transcription_segment
          :for={{segment, index} <- Enum.with_index(@segments)}
          class="text-lg"
          index={index}
          segment={segment}
        />
      </LiveAiElements.Components.Transcription.transcription>
    </div>
    """
  end

  defp voice_selector_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-1">
      <LiveAiElements.Components.VoiceSelector.voice_selector_name>
        Vega
      </LiveAiElements.Components.VoiceSelector.voice_selector_name>
      <LiveAiElements.Components.VoiceSelector.voice_selector_description>
        Warm, unhurried, and a little dry.
      </LiveAiElements.Components.VoiceSelector.voice_selector_description>
      <LiveAiElements.Components.VoiceSelector.voice_selector_attributes>
        <LiveAiElements.Components.VoiceSelector.voice_selector_accent>
          British
        </LiveAiElements.Components.VoiceSelector.voice_selector_accent>
        <LiveAiElements.Components.VoiceSelector.voice_selector_bullet />
        <LiveAiElements.Components.VoiceSelector.voice_selector_age>
          Adult
        </LiveAiElements.Components.VoiceSelector.voice_selector_age>
      </LiveAiElements.Components.VoiceSelector.voice_selector_attributes>
    </div>
    """
  end

  # The chrome only, on both sides. shiki tokenises in the browser, so a
  # screenshot of upstream's body is a race between the page and the
  # highlighter — and the tokens are the caller's to supply here, which is a
  # different fixture rather than a different component.
  defp code_block_default(assigns) do
    ~H"""
    <LiveAiElements.Components.CodeBlock.code_block_container language="shell" class="max-w-md">
      <LiveAiElements.Components.CodeBlock.code_block_header>
        <LiveAiElements.Components.CodeBlock.code_block_filename>
          Makefile
        </LiveAiElements.Components.CodeBlock.code_block_filename>
        <LiveAiElements.Components.CodeBlock.code_block_actions>
          <LiveAiElements.Components.CodeBlock.code_block_copy_button
            id="copy-code"
            code="mix ui.spec"
            aria-label="Copy the code"
          />
        </LiveAiElements.Components.CodeBlock.code_block_actions>
      </LiveAiElements.Components.CodeBlock.code_block_header>
    </LiveAiElements.Components.CodeBlock.code_block_container>
    """
  end

  defp open_in_chat_default(assigns) do
    assigns = assign(assigns, :query, "How can I implement authentication in Next.js?")

    ~H"""
    <.dropdown_menu
      id="open-in-chat"
      class="static! w-[240px] border bg-popover! p-1 shadow-md ring-0! before:hidden!"
      align="start"
      trigger_class={LiveAiElements.Shadcn.button_class("default", "outline")}
    >
      <:trigger>
        Open in chat <LiveShadcn.Icon.icon name="chevron-down" class="size-4" />
      </:trigger>
      <LiveAiElements.Components.OpenInChat.open_in_chat_gpt
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
      <LiveAiElements.Components.OpenInChat.open_in_claude
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
      <LiveAiElements.Components.OpenInChat.open_in_cursor
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
      <LiveAiElements.Components.OpenInChat.open_in_t3
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
      <LiveAiElements.Components.OpenInChat.open_in_scira
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
      <LiveAiElements.Components.OpenInChat.open_inv0
        query={@query}
        data-slot="dropdown-menu-item"
        role="menuitem"
        tabindex="-1"
        class={LiveShadcn.UI.DropdownMenu.item_class()}
      />
    </.dropdown_menu>
    """
  end

  defp connection_default(assigns) do
    ~H"""
    <svg class="h-24 w-64" viewBox="0 0 240 96">
      <LiveAiElements.Components.Connection.connection from_x={8} from_y={16} to_x={220} to_y={80} />
    </svg>
    """
  end

  defp controls_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Controls.controls class="w-fit">
      <button type="button" class="p-1" aria-label="Zoom in">+</button><button
        type="button"
        class="p-1"
        aria-label="Zoom out"
      >-</button>
    </LiveAiElements.Components.Controls.controls>
    """
  end

  defp edge_default(assigns) do
    ~H"""
    <svg class="h-24 w-64" viewBox="0 0 240 96">
      <LiveAiElements.Components.Edge.edge_temporary
        id="wire"
        edge_path="M8,16 C 114,16 114,80 220,80"
      />
    </svg>
    """
  end

  defp edge_animated(assigns) do
    ~H"""
    <svg class="h-24 w-64" viewBox="0 0 240 96">
      <LiveAiElements.Components.Edge.edge_animated
        id="animated-wire"
        edge_path="M8,16 C 114,16 114,80 220,80"
        source_node="reader"
        target_node="writer"
        style="stroke: rgb(37, 99, 235)"
      />
    </svg>
    """
  end

  defp jsx_preview_default(assigns) do
    ~H"""
    <LiveAiElements.Components.JsxPreview.jsx_preview class="max-w-md">
      <LiveAiElements.Components.JsxPreview.jsx_preview_content>
        <p class="text-sm">What the model wrote, already markup.</p>
      </LiveAiElements.Components.JsxPreview.jsx_preview_content>
    </LiveAiElements.Components.JsxPreview.jsx_preview>
    """
  end

  defp node_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Node.node handles={%{target: false, source: false}}>
      <LiveAiElements.Components.Node.node_header>
        <LiveAiElements.Components.Node.node_title>Reader</LiveAiElements.Components.Node.node_title>
      </LiveAiElements.Components.Node.node_header>
      <LiveAiElements.Components.Node.node_content>
        Reads a registry source and writes a spec.
      </LiveAiElements.Components.Node.node_content>
    </LiveAiElements.Components.Node.node>
    """
  end

  defp panel_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Panel.panel class="w-fit">
      <span class="text-xs">62 components</span>
    </LiveAiElements.Components.Panel.panel>
    """
  end

  defp persona_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Persona.persona id="persona" />
    """
  end

  defp toolbar_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Toolbar.toolbar class="w-fit">
      <button type="button" class="text-xs" aria-label="Run">Run</button>
    </LiveAiElements.Components.Toolbar.toolbar>
    """
  end

  defp agent_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Agent.agent class="max-w-md">
      <LiveAiElements.Components.Agent.agent_header name="Reader" model="claude-opus-4.5" />
      <LiveAiElements.Components.Agent.agent_content>
        <LiveAiElements.Components.Agent.agent_instructions>
          Read every registry source and write one spec for each.
        </LiveAiElements.Components.Agent.agent_instructions>
      </LiveAiElements.Components.Agent.agent_content>
    </LiveAiElements.Components.Agent.agent>
    """
  end

  defp audio_player_default(assigns) do
    ~H"""
    <%!-- A custom element owns its own DOM: media-chrome writes `mediapaused`,
         `mediavolume` and a dozen more onto the controller once the browser
         upgrades it, and re-renders its buttons from them. `phx-update="ignore"`
         is what hands the subtree over, and every LiveView that renders a
         custom element needs it. --%>
    <div class="flex size-full items-center justify-center">
      <LiveAiElements.Components.AudioPlayer.audio_player id="player" phx-update="ignore">
        <LiveAiElements.Components.AudioPlayer.audio_player_element
          src="https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/ElevenLabs_2025-11-10T22_07_46_Hayden_pvc_sp108_s50_sb75_se0_b_m2.mp3"
          preload="metadata"
        />
        <LiveAiElements.Components.AudioPlayer.audio_player_control_bar>
          <LiveAiElements.Components.AudioPlayer.audio_player_play_button />
          <LiveAiElements.Components.AudioPlayer.audio_player_seek_backward_button />
          <LiveAiElements.Components.AudioPlayer.audio_player_seek_forward_button />
          <LiveAiElements.Components.AudioPlayer.audio_player_time_display />
          <LiveAiElements.Components.AudioPlayer.audio_player_time_range />
          <LiveAiElements.Components.AudioPlayer.audio_player_duration_display />
          <LiveAiElements.Components.AudioPlayer.audio_player_mute_button />
          <LiveAiElements.Components.AudioPlayer.audio_player_volume_range />
        </LiveAiElements.Components.AudioPlayer.audio_player_control_bar>
      </LiveAiElements.Components.AudioPlayer.audio_player>
    </div>
    """
  end

  defp context_default(assigns) do
    ~H"""
    <div class="max-w-xs space-y-1">
      <%!-- The cost is `$0.00` because no model was named, which is what
      upstream draws when it has no price to look up: a component that draws a
      price is not the thing that knows the price. --%>
      <LiveAiElements.Components.Context.context_input_usage
        input_tokens={12_400}
        input_cost_text="$0.00"
      />
    </div>
    """
  end

  defp conversation_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Conversation.conversation id="log" class="h-40 max-w-md border">
      <p :for={line <- 1..6} class="text-sm">Message {line}</p>
    </LiveAiElements.Components.Conversation.conversation>
    """
  end

  defp prompt_input_default(assigns) do
    ~H"""
    <%!-- The textarea is a direct child. `prompt_input_body` is
         `display: contents`, and the input group grows to fit a textarea with
         `has-[>textarea]:h-auto` — a selector that asks about a DOM child, which
         `display: contents` does not change. Wrapped, the group keeps its
         one-line height and squeezes the textarea to nothing. --%>
    <LiveAiElements.Components.PromptInput.prompt_input class="max-w-md">
      <LiveAiElements.Components.PromptInput.prompt_input_textarea
        id="prompt-textarea"
        placeholder="What would you like to know?"
      />
      <LiveAiElements.Components.PromptInput.prompt_input_footer>
        <LiveAiElements.Components.PromptInput.prompt_input_tools />
        <LiveAiElements.Components.PromptInput.prompt_input_submit />
      </LiveAiElements.Components.PromptInput.prompt_input_footer>
    </LiveAiElements.Components.PromptInput.prompt_input>
    """
  end

  defp sandbox_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Sandbox.sandbox_tabs_bar class="max-w-md">
      <span class="text-muted-foreground text-xs">Files</span>
    </LiveAiElements.Components.Sandbox.sandbox_tabs_bar>
    """
  end

  defp file_tree_default(assigns) do
    ~H"""
    <LiveAiElements.Components.FileTree.file_tree>
      <LiveAiElements.Components.FileTree.file_tree_folder
        id="src-folder"
        name="src"
        path="src"
        is_expanded="true"
      >
        <LiveAiElements.Components.FileTree.file_tree_folder
          id="components-folder"
          name="components"
          path="src/components"
          is_expanded="true"
        >
          <LiveAiElements.Components.FileTree.file_tree_file
            name="button.tsx"
            path="src/components/button.tsx"
          />
          <LiveAiElements.Components.FileTree.file_tree_file
            name="input.tsx"
            path="src/components/input.tsx"
          />
        </LiveAiElements.Components.FileTree.file_tree_folder>
        <LiveAiElements.Components.FileTree.file_tree_file name="index.ts" path="src/index.ts" />
      </LiveAiElements.Components.FileTree.file_tree_folder>
    </LiveAiElements.Components.FileTree.file_tree>
    """
  end

  defp schema_display_default(assigns) do
    ~H"""
    <div class="max-w-md space-y-2">
      <LiveAiElements.Components.SchemaDisplay.schema_display>
        <LiveAiElements.Components.SchemaDisplay.schema_display_header>
          <LiveAiElements.Components.SchemaDisplay.schema_display_method
            method="GET"
            variant="secondary"
          />
          <%!-- Upstream highlights a path parameter through
                `dangerouslySetInnerHTML`. HEEx has no such door and needs none:
                the caller writes the `{name}` it wants coloured. --%>
          <LiveAiElements.Components.SchemaDisplay.schema_display_path phx-no-format>/components/<span class="text-blue-600 dark:text-blue-400">{"{name}"}</span></LiveAiElements.Components.SchemaDisplay.schema_display_path>
        </LiveAiElements.Components.SchemaDisplay.schema_display_header>
        <LiveAiElements.Components.SchemaDisplay.schema_display_description description="One component, by name." />
      </LiveAiElements.Components.SchemaDisplay.schema_display>
    </div>
    """
  end

  # Composed rather than left to draw itself. Upstream's two header buttons are
  # an icon each and no words, which axe reports and is right to — so the
  # example names them, which is the caller's to do and costs no pixels.
  defp terminal_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Terminal.terminal
      id="build"
      output="Compiling 4 files (.ex)"
      class="max-w-md"
    >
      <LiveAiElements.Components.Terminal.terminal_header>
        <LiveAiElements.Components.Terminal.terminal_title />
        <div class="flex items-center gap-1">
          <LiveAiElements.Components.Terminal.terminal_status />
          <LiveAiElements.Components.Terminal.terminal_actions>
            <LiveAiElements.Components.Terminal.terminal_copy_button
              id="copy-output"
              output="Compiling 4 files (.ex)"
              aria-label="Copy the output"
            />
            <LiveAiElements.Components.Terminal.terminal_clear_button aria-label="Clear the output" />
          </LiveAiElements.Components.Terminal.terminal_actions>
        </div>
      </LiveAiElements.Components.Terminal.terminal_header>
      <LiveAiElements.Components.Terminal.terminal_content output="Compiling 4 files (.ex)" />
    </LiveAiElements.Components.Terminal.terminal>
    """
  end

  defp shimmer_default(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center gap-4 p-8">
      <LiveAiElements.Components.Shimmer.shimmer id="thinking">
        This text has a shimmer effect
      </LiveAiElements.Components.Shimmer.shimmer>
      <LiveAiElements.Components.Shimmer.shimmer id="heading" as="h1" class="font-bold text-4xl">
        Large Heading
      </LiveAiElements.Components.Shimmer.shimmer>
      <LiveAiElements.Components.Shimmer.shimmer id="slower" duration={3} spread={3}>
        Slower shimmer with wider spread
      </LiveAiElements.Components.Shimmer.shimmer>
    </div>
    """
  end

  defp inline_citation_default(assigns) do
    ~H"""
    <div class="max-w-md space-y-3">
      <LiveAiElements.Components.InlineCitation.inline_citation>
        <LiveAiElements.Components.InlineCitation.inline_citation_text>
          Base UI renders no element for a popover's root.
        </LiveAiElements.Components.InlineCitation.inline_citation_text>
      </LiveAiElements.Components.InlineCitation.inline_citation>
      <%!-- The source's own title is an `<h4>`, and the deepest heading a
      preview page has is the `<h2>` it gives the example. A page that skips a
      level is one axe reports, and it is this page that skips it. --%>
      <h3 class="sr-only">Source</h3>
      <LiveAiElements.Components.InlineCitation.inline_citation_source
        title="Popover"
        url="https://base-ui.com/react/components/popover"
        description="The root is a state container and draws nothing of its own."
      />
    </div>
    """
  end

  defp inline_citation_carousel(assigns) do
    sources = [
      %{
        title: "Advances in Natural Language Processing",
        url: "https://example.com/nlp-advances",
        description: "A study of recent natural language processing systems."
      },
      %{
        title: "Breakthroughs in Machine Learning",
        url: "https://mlnews.org/breakthroughs",
        description: "A review of important machine learning results."
      }
    ]

    assigns = assign(assigns, :sources, sources)

    ~H"""
    <div class="w-80">
      <h3 class="sr-only">Sources</h3>
      <LiveAiElements.Components.InlineCitation.inline_citation_carousel
        id="citation-carousel"
        aria-label="Citation sources"
      >
        <LiveAiElements.Components.InlineCitation.inline_citation_carousel_header>
          <LiveAiElements.Components.InlineCitation.inline_citation_carousel_prev />
          <LiveAiElements.Components.InlineCitation.inline_citation_carousel_next />
          <LiveAiElements.Components.InlineCitation.inline_citation_carousel_index />
        </LiveAiElements.Components.InlineCitation.inline_citation_carousel_header>
        <LiveAiElements.Components.InlineCitation.inline_citation_carousel_content>
          <LiveAiElements.Components.InlineCitation.inline_citation_carousel_item :for={
            source <- @sources
          }>
            <LiveAiElements.Components.InlineCitation.inline_citation_source
              title={source.title}
              url={source.url}
              description={source.description}
            />
          </LiveAiElements.Components.InlineCitation.inline_citation_carousel_item>
        </LiveAiElements.Components.InlineCitation.inline_citation_carousel_content>
      </LiveAiElements.Components.InlineCitation.inline_citation_carousel>
    </div>
    """
  end

  # The trace the example copies, and the frames a reader of it draws. Upstream
  # parses the string into a context; here the caller passes what it parsed.
  #
  # `isInternal` is upstream's rule — a path under `node_modules`, or one
  # starting with `node:` — and it dims the frames that are somebody else's.
  @trace """
  TypeError: Cannot read properties of undefined (reading 'slots')
      at divergence (storybook/test/browser/parity.spec.mjs:142:31)
      at compare (storybook/test/browser/measure.mjs:88:14)
      at TestFunction (node_modules/@playwright/test/lib/worker.js:184:9)
      at node:internal/process/task_queues:95:5\
  """

  @frames [
    %{
      raw: "at divergence (storybook/test/browser/parity.spec.mjs:142:31)",
      functionName: "divergence",
      filePath: "storybook/test/browser/parity.spec.mjs",
      lineNumber: 142,
      columnNumber: 31,
      isInternal: false
    },
    %{
      raw: "at compare (storybook/test/browser/measure.mjs:88:14)",
      functionName: "compare",
      filePath: "storybook/test/browser/measure.mjs",
      lineNumber: 88,
      columnNumber: 14,
      isInternal: false
    },
    %{
      raw: "at TestFunction (node_modules/@playwright/test/lib/worker.js:184:9)",
      functionName: "TestFunction",
      filePath: "node_modules/@playwright/test/lib/worker.js",
      lineNumber: 184,
      columnNumber: 9,
      isInternal: true
    },
    %{
      raw: "at node:internal/process/task_queues:95:5",
      functionName: nil,
      filePath: "node:internal/process/task_queues",
      lineNumber: 95,
      columnNumber: 5,
      isInternal: true
    }
  ]

  defp stack_trace_default(assigns) do
    assigns = assign(assigns, trace: @trace, frames: @frames)

    ~H"""
    <LiveAiElements.Components.StackTrace.stack_trace class="max-w-md">
      <LiveAiElements.Components.StackTrace.stack_trace_header>
        <LiveAiElements.Components.StackTrace.stack_trace_error>
          <LiveAiElements.Components.StackTrace.stack_trace_error_type>
            TypeError
          </LiveAiElements.Components.StackTrace.stack_trace_error_type>
          <LiveAiElements.Components.StackTrace.stack_trace_error_message>
            Cannot read properties of undefined (reading 'slots')
          </LiveAiElements.Components.StackTrace.stack_trace_error_message>
        </LiveAiElements.Components.StackTrace.stack_trace_error>
        <LiveAiElements.Components.StackTrace.stack_trace_actions>
          <LiveAiElements.Components.StackTrace.stack_trace_copy_button
            id="copy-trace"
            raw={@trace}
            aria-label="Copy the trace"
          />
          <LiveAiElements.Components.StackTrace.stack_trace_expand_button is_open="true" />
        </LiveAiElements.Components.StackTrace.stack_trace_actions>
      </LiveAiElements.Components.StackTrace.stack_trace_header>
      <LiveAiElements.Components.StackTrace.stack_trace_frames frames_to_show={@frames} />
    </LiveAiElements.Components.StackTrace.stack_trace>
    """
  end

  @summary %{total: 8, passed: 6, failed: 2, skipped: 0, duration: 1240}

  defp test_results_default(assigns) do
    assigns = assign(assigns, summary: @summary)

    ~H"""
    <LiveAiElements.Components.TestResults.test_results class="max-w-md">
      <LiveAiElements.Components.TestResults.test_results_header>
        <LiveAiElements.Components.TestResults.test_results_summary summary={@summary} />
        <LiveAiElements.Components.TestResults.test_results_duration summary={@summary} />
      </LiveAiElements.Components.TestResults.test_results_header>
      <LiveAiElements.Components.TestResults.test_results_content>
        <LiveAiElements.Components.TestResults.test_results_progress
          summary={@summary}
          passed_percent={75}
          failed_percent="25"
        />
      </LiveAiElements.Components.TestResults.test_results_content>
    </LiveAiElements.Components.TestResults.test_results>
    """
  end

  defp tool_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Tool.tool
      id="read-spec"
      title="read_spec"
      state="output-available"
      variant="secondary"
      open
      class="max-w-md"
    >
      Read `registry/spec/ai_elements/tool.json`.
    </LiveAiElements.Components.Tool.tool>
    """
  end

  defp web_preview_default(assigns) do
    ~H"""
    <LiveAiElements.Components.WebPreview.web_preview id="web-preview" class="h-64 max-w-md">
      <LiveAiElements.Components.WebPreview.web_preview_navigation>
        <LiveAiElements.Components.WebPreview.web_preview_url value="https://example.com" />
      </LiveAiElements.Components.WebPreview.web_preview_navigation>
      <LiveAiElements.Components.WebPreview.web_preview_body />
    </LiveAiElements.Components.WebPreview.web_preview>
    """
  end

  defp artifact_default(assigns) do
    ~H"""
    <LiveAiElements.Components.Artifact.artifact class="max-w-md">
      <LiveAiElements.Components.Artifact.artifact_header>
        <div>
          <LiveAiElements.Components.Artifact.artifact_title>
            accordion.ex
          </LiveAiElements.Components.Artifact.artifact_title>
          <LiveAiElements.Components.Artifact.artifact_description>
            Generated from registry/spec/shadcn/accordion.json
          </LiveAiElements.Components.Artifact.artifact_description>
        </div>
        <LiveAiElements.Components.Artifact.artifact_close />
      </LiveAiElements.Components.Artifact.artifact_header>
      <LiveAiElements.Components.Artifact.artifact_content>
        Four functions, one hook, and no class string typed by a person.
      </LiveAiElements.Components.Artifact.artifact_content>
    </LiveAiElements.Components.Artifact.artifact>
    """
  end

  # The device list is the caller's here and the browser's upstream: React reads
  # `navigator.mediaDevices`, which needs a permission prompt and reports
  # nothing without one. A server has no such list, so the options are given.
  defp mic_selector_default(assigns) do
    ~H"""
    <div class="flex size-full flex-col items-center justify-center gap-4">
      <LiveAiElements.Components.MicSelector.mic_selector
        id="mic"
        name="mic"
        placeholder="Select microphone..."
        trigger_class="w-full max-w-sm"
      >
        <:option value="built-in" label="Built-in microphone" />
        <:option value="usb" label="USB microphone" />
      </LiveAiElements.Components.MicSelector.mic_selector>
    </div>
    """
  end

  defp plan_default(assigns) do
    ~H"""
    <%!-- Upstream's trigger is an icon button — a chevron and a screen-reader
         label, in a `size-8` box — so the title it takes is empty. Text put in
         it overflows the button and is clipped by the card. --%>
    <.plan id="rollout" title="" class="max-w-md">
      Read the source, write the spec, generate the module.
    </.plan>
    """
  end

  # The hover card is the application's own, wrapped around a part of the
  # dependency. `attachments` exports three wrappers around one upstream, and
  # this is what they were wrapping — a caller composes it in one place instead
  # of naming a module that `mix ui.add` renamed.
  defp attachments_default(assigns) do
    ~H"""
    <AiAttachments.attachments variant="list" class="max-w-md">
      <.hover_card
        id="spec-preview"
        align="start"
        align_offset="0"
        class="w-auto! rounded-md! border p-2! text-base! leading-6! shadow-md! ring-0!"
      >
        <:trigger>
          <AiAttachments.attachment variant="list">
            <AiAttachments.attachment_preview variant="list">
              <LiveShadcn.Icon.icon name="file-text" class="size-4 text-muted-foreground" />
            </AiAttachments.attachment_preview>
            <AiAttachments.attachment_info
              label="accordion.json"
              data={%{mediaType: "application/json"}}
              show_media_type
            />
          </AiAttachments.attachment>
        </:trigger>
        The contract the accordion port uses.
      </.hover_card>
      <AiAttachments.attachment variant="list">
        <AiAttachments.attachment_preview variant="list">
          <LiveShadcn.Icon.icon name="image" class="size-4 text-muted-foreground" />
        </AiAttachments.attachment_preview>
        <AiAttachments.attachment_info
          label="upstream.png"
          data={%{mediaType: "image/png"}}
          show_media_type
        />
        <AiAttachments.attachment_remove label="Remove upstream.png" variant="list" />
      </AiAttachments.attachment>
    </AiAttachments.attachments>
    """
  end

  # `show_values` is the server's, and the switch pushes an event to move it.
  # That is one round trip per reveal, stated rather than hidden: the value is a
  # secret, and a page that had been given it could not un-give it.
  defp environment_variables_default(assigns) do
    ~H"""
    <.environment_variables class="max-w-md">
      <.environment_variables_header>
        <.environment_variables_title />
        <.environment_variables_toggle show_values={@show_values} on_toggle="toggle_values" />
      </.environment_variables_header>
      <.environment_variables_content>
        <.environment_variable>
          <.environment_variable_group>
            <.environment_variable_name name="MIX_ENV" />
            <.environment_variable_required />
          </.environment_variable_group>
          <.environment_variable_group>
            <%!-- Masked until the reader asks, like the secret below it: what a
                  value is worth hiding is the caller's decision, and upstream
                  hides every one of them. --%>
            <.environment_variable_value
              display_value={if @show_values, do: "prod", else: "••••"}
              show_values={@show_values}
            />
            <.environment_variable_copy_button
              id="copy-mix-env"
              name="MIX_ENV"
              value="prod"
              aria-label="Copy MIX_ENV"
            />
          </.environment_variable_group>
        </.environment_variable>
        <.environment_variable>
          <.environment_variable_group>
            <.environment_variable_name name="SECRET_KEY_BASE" />
          </.environment_variable_group>
          <.environment_variable_group>
            <.environment_variable_value
              display_value={if @show_values, do: "sup3rs3cr3t", else: "•••••••••••"}
              show_values={@show_values}
            />
            <.environment_variable_copy_button
              id="copy-secret-key-base"
              name="SECRET_KEY_BASE"
              value={if @show_values, do: "sup3rs3cr3t", else: ""}
              aria-label="Copy SECRET_KEY_BASE"
            />
          </.environment_variable_group>
        </.environment_variable>
      </.environment_variables_content>
    </.environment_variables>
    """
  end

  defp ai_message_default(assigns) do
    ~H"""
    <AiMessage.message from="assistant" class="max-w-md">
      <AiMessage.message_content>
        <AiMessage.message_response content="It is **18 degrees** and clear in Cluj." />
      </AiMessage.message_content>
    </AiMessage.message>
    """
  end

  defp drawer_default(assigns) do
    ~H"""
    <.drawer id="stages">
      <:trigger>Stages</:trigger>
      <:title>What the pipeline does</:title>
      <:description>Four stages, each with an artefact of its own.</:description>
      <p class="text-sm">Fetch, spec, generate, verify.</p>
    </.drawer>
    """
  end

  # The bar is the component; every menu inside it is a dropdown menu, because
  # a menu's parts have to agree about which menu they belong to and that is
  # what the one folded function is for.
  defp menubar_default(assigns) do
    ~H"""
    <.menubar>
      <.dropdown_menu
        id="menubar-file"
        trigger_slot="menubar-trigger"
        popup_slot="menubar-content"
        item_slot="menubar-item"
        trigger_class="cn-menubar-trigger flex items-center outline-hidden select-none"
        class="cn-menubar-content cn-menubar-content-logical cn-menu-target cn-menu-translucent"
        item_class="cn-menubar-item group/menubar-item"
        align_offset="-4"
        side_offset="8"
      >
        <:trigger>File</:trigger>
        <:item value="fetch">Fetch upstream</:item>
        <:item value="spec">Rebuild specs</:item>
      </.dropdown_menu>
      <.dropdown_menu
        id="menubar-view"
        trigger_slot="menubar-trigger"
        popup_slot="menubar-content"
        item_slot="menubar-item"
        trigger_class="cn-menubar-trigger flex items-center outline-hidden select-none"
        class="cn-menubar-content cn-menubar-content-logical cn-menu-target cn-menu-translucent"
        item_class="cn-menubar-item group/menubar-item"
        align_offset="-4"
        side_offset="8"
      >
        <:trigger>View</:trigger>
        <:item value="verified">Verified only</:item>
        <:item value="all">Everything</:item>
      </.dropdown_menu>
    </.menubar>
    """
  end

  defp input_group_default(assigns) do
    ~H"""
    <.input_group class="max-w-sm">
      <.input_group_addon align="inline-start">
        <.input_group_text>https://</.input_group_text>
      </.input_group_addon>
      <.input_group_input id="site" name="site" value="hex.pm" aria-label="Site" />
      <.input_group_addon align="inline-end">
        <.input_group_text>/packages</.input_group_text>
      </.input_group_addon>
    </.input_group>
    """
  end

  defp native_select_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-2">
      <.label id="recipe-label" for="recipe">Recipe</.label>
      <.native_select id="recipe" name="recipe" aria-labelledby="recipe-label">
        <.native_select_option value="disclosure" selected>Disclosure</.native_select_option>
        <.native_select_option value="dialog">Dialog</.native_select_option>
        <.native_select_option value="listbox">Listbox</.native_select_option>
      </.native_select>
    </div>
    """
  end

  # `sidebar_inset` is left out on purpose. It is a `<main>` — the page's own
  # content area, beside the sidebar — and this page already has one around
  # every example. Drawing a second inside the first is what a real page never
  # does, and axe is right to say so.
  defp scroll_area_default(assigns) do
    ~H"""
    <.scroll_area id="stages" class="h-40 w-full max-w-sm rounded-md border p-4">
      <p :for={n <- 1..12} class="pb-2 text-sm">Pass {n}: the reader settles when no file moves.</p>
    </.scroll_area>
    """
  end

  defp slider_default(assigns) do
    ~H"""
    <.slider id="passes" name="passes" value={[3]} min={1} max={5} label="Passes" class="max-w-sm" />
    """
  end

  defp slider_range(assigns) do
    ~H"""
    <.slider
      id="tiers"
      name="tiers"
      value={[20, 80]}
      label="Tier range"
      class="max-w-sm"
    />
    """
  end

  # `duration={0}` on purpose. Every check on this page — the snapshot, axe, the
  # behaviour suite — reads the page after it has settled, and a stack that
  # empties itself five seconds in is a different page each time it is read.
  # A toast that stays until it is closed is the same page every run.
  defp toast_default(assigns) do
    ~H"""
    <.toaster id="notices" dismiss="dismiss_toast" duration={0} limit={2}>
      <:toast :for={notice <- @toasts} id={notice.id} type={notice.type} title={notice.title}>
        {notice.description}
      </:toast>
    </.toaster>
    """
  end

  # A sidebar is navigation for a whole page, so an example that draws four
  # links in a 16rem-tall box demonstrates nothing: collapsing it changes
  # nothing a reader can see, which is the one thing this component does.
  #
  # This is the shape a real one has — a brand, two labelled groups, a footer
  # holding whoever is signed in — and it is tall enough that the trigger and
  # the rail visibly do their job.
  #
  # `sidebar_inset` is left out on purpose. It is a `<main>`, this page already
  # has one around every example, and a second inside the first is what a real
  # page never does. axe is right to say so.
  defp sidebar_default(assigns) do
    assigns =
      assign(assigns,
        pipeline: [
          {"Fetch", "cloud-download"},
          {"Spec", "file-json"},
          {"Generate", "wand-sparkles"},
          {"Verify", "circle-check"}
        ],
        registry: [{"Components", "boxes"}, {"Recipes", "book-open"}, {"Upstream", "git-branch"}]
      )

    ~H"""
    <.sidebar_provider class="min-h-96">
      <.sidebar id="nav" collapsible="icon">
        <.sidebar_header>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.sidebar_menu_button size="lg">
                <LiveShadcn.Icon.icon name="component" class="size-4" />
                <span class="font-semibold">live_shadcn</span>
              </.sidebar_menu_button>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_header>

        <.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Pipeline</.sidebar_group_label>
            <.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item :for={{stage, icon} <- @pipeline}>
                  <.sidebar_menu_button is_active={stage == "Spec"}>
                    <LiveShadcn.Icon.icon name={icon} class="size-4" />
                    <span>{stage}</span>
                  </.sidebar_menu_button>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>

          <.sidebar_separator />

          <.sidebar_group>
            <.sidebar_group_label>Registry</.sidebar_group_label>
            <.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item :for={{item, icon} <- @registry}>
                  <.sidebar_menu_button>
                    <LiveShadcn.Icon.icon name={icon} class="size-4" />
                    <span>{item}</span>
                  </.sidebar_menu_button>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content>

        <.sidebar_footer>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.sidebar_menu_button>
                <LiveShadcn.Icon.icon name="circle-user" class="size-4" />
                <span>Signed in</span>
              </.sidebar_menu_button>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_footer>

        <.sidebar_rail for="nav" collapsible="icon" />
      </.sidebar>

      <div class="flex flex-1 items-start gap-2 p-3">
        <.sidebar_trigger for="nav" collapsible="icon" />
        <p class="text-sm text-muted-foreground">
          The trigger and the rail both flip one attribute, and every class string reads it.
          No round trip.
        </p>
      </div>
    </.sidebar_provider>
    """
  end

  defp question_default(assigns) do
    ~H"""
    <.question id="framework-question" class="w-full max-w-2xl">
      <div class="space-y-1">
        <.question_prompt>Which framework should we use?</.question_prompt>
        <.question_description>Select one option.</.question_description>
      </div>
      <.question_options selection_mode="single" aria-label="Framework">
        <.question_option value="Next.js" role="radio" is_selected="false">Next.js</.question_option>
        <.question_option value="Nuxt" role="radio" is_selected="false">Nuxt</.question_option>
        <.question_option value="SvelteKit" role="radio" is_selected="false">
          SvelteKit
        </.question_option>
      </.question_options>
      <.question_actions>
        <.question_submit has_response="false">Continue</.question_submit>
      </.question_actions>
    </.question>
    """
  end

  defp questionnaire_default(assigns) do
    ~H"""
    <.questionnaire>
      <.questionnaire_progress current={1} total={2}>1 of 2</.questionnaire_progress>
      <.questionnaire_item>
        <.questionnaire_title>How should the server filter commands?</.questionnaire_title>
        <.questionnaire_description>
          Choose one behaviour for each keystroke.
        </.questionnaire_description>
        <.questionnaire_choices class="mt-4 gap-2">
          <.questionnaire_choice>
            On the server
            <.questionnaire_choice_description>
              One round trip per keystroke.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice>
            In the browser
            <.questionnaire_choice_description>
              Keep a second copy of the list.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
        </.questionnaire_choices>
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  defp snippet_default(assigns) do
    ~H"""
    <.snippet class="max-w-md">
      <.snippet_addon align="inline-start">
        <.snippet_text>$</.snippet_text>
      </.snippet_addon>
      <.snippet_input
        code="mix ui.add accordion"
        type="text"
        aria-label="The command"
        readonly
      />
      <.snippet_addon align="inline-end">
        <.snippet_copy_button
          id="snippet-copy"
          code="mix ui.add accordion"
          variant="ghost"
          size="icon-sm"
        />
      </.snippet_addon>
    </.snippet>
    """
  end

  defp field_default(assigns) do
    ~H"""
    <.field class="max-w-sm">
      <.field_label for="registry">Registry</.field_label>
      <.field_content>
        <.input id="registry" name="registry" value="shadcn" />
        <.field_description>Which upstream registry to read.</.field_description>
      </.field_content>
    </.field>
    """
  end

  defp package_info_default(assigns) do
    ~H"""
    <.package_info class="max-w-sm">
      <.package_info_header>
        <.package_info_name>phoenix_live_view</.package_info_name>
        <.package_info_change_type change_type="minor">minor</.package_info_change_type>
      </.package_info_header>
      <.package_info_content>
        <.package_info_description>
          The framework every component is built on.
        </.package_info_description>
      </.package_info_content>
    </.package_info>
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
      The upstream sources stay where they are. <code>mix ui.spec</code>
      restores safe
      upstream facts after the port is reviewed.
      <:footer>
        <.button variant="ghost" phx-click={LiveBase.Dialog.close("confirm")}>Cancel</.button>
        <.button variant="destructive">Delete</.button>
      </:footer>
    </.dialog>
    """
  end

  defp dropdown_menu_default(assigns) do
    ~H"""
    <.dropdown_menu id="actions" trigger_variant="outline" class="w-40" grouped>
      <:trigger>Open</:trigger>
      <:entry kind="label">My Account</:entry>
      <:entry kind="item" value="profile" shortcut="⇧⌘P">Profile</:entry>
      <:entry kind="item" value="billing" shortcut="⌘B">Billing</:entry>
      <:entry kind="item" value="settings" shortcut="⌘S">Settings</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="team">Team</:entry>
      <:entry
        kind="submenu"
        value="invite-users"
        items={[
          %{value: "email", label: "Email"},
          %{value: "message", label: "Message"},
          %{kind: "separator"},
          %{value: "more", label: "More..."}
        ]}
      >
        Invite users
      </:entry>
      <:entry kind="item" value="new-team" shortcut="⌘+T">New Team</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="github">GitHub</:entry>
      <:entry kind="item" value="support">Support</:entry>
      <:entry kind="item" value="api" disabled>API</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" shortcut="⇧⌘Q">Log out</:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_checkboxes(assigns) do
    ~H"""
    <.dropdown_menu id="appearance" trigger_variant="outline" class="w-40" grouped>
      <:trigger>Open</:trigger>
      <:entry kind="label">Appearance</:entry>
      <:entry kind="checkbox" value="status-bar" checked>Status Bar</:entry>
      <:entry kind="checkbox" value="activity-bar" disabled>Activity Bar</:entry>
      <:entry kind="checkbox" value="panel">Panel</:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_radio_group(assigns) do
    ~H"""
    <.dropdown_menu
      id="panel-position"
      trigger_variant="outline"
      class="w-32"
      grouped
    >
      <:trigger>Open</:trigger>
      <:entry kind="label">Panel Position</:entry>
      <:entry
        kind="radio-group"
        group="position"
        value="bottom"
        items={[
          %{value: "top", label: "Top"},
          %{value: "bottom", label: "Bottom"},
          %{value: "right", label: "Right"}
        ]}
      />
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_complex(assigns) do
    ~H"""
    <.dropdown_menu id="complex-actions" trigger_variant="outline" class="min-w-40" grouped>
      <:trigger>Open</:trigger>
      <:entry kind="label">My Account</:entry>
      <:entry kind="item" value="profile" shortcut="⇧⌘P">Profile</:entry>
      <:entry kind="item" value="billing" shortcut="⌘B">Billing</:entry>
      <:entry kind="item" value="settings" shortcut="⌘S">Settings</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="team">Team</:entry>
      <:entry
        kind="submenu"
        value="invite-users"
        items={[
          %{value: "email", label: "Email"},
          %{value: "message", label: "Message"},
          %{kind: "separator"},
          %{value: "more", label: "More..."}
        ]}
      >
        Invite users
      </:entry>
      <:entry kind="item" value="new-team" shortcut="⌘+T">New Team</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="github">GitHub</:entry>
      <:entry kind="item" value="support">Support</:entry>
      <:entry kind="item" value="api" disabled>API</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" shortcut="⇧⌘Q">Log out</:entry>
    </.dropdown_menu>
    """
  end

  defp empty_default(assigns) do
    ~H"""
    <.empty class="max-w-sm">
      <.empty_header>
        <.empty_title>No components yet</.empty_title>
        <.empty_description>Run `mix ui.fetch` to discover the registry.</.empty_description>
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
    <.progress value="62" label="Generating" class="max-w-sm">
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

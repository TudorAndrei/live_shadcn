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

  @toast_examples %{
    "default" => [],
    "types" => [],
    "promise" => [],
    "marker" => [],
    "questionnaire-card" => [],
    "questionnaire-dialog" => [],
    "message-scroller-load-history" => []
  }

  @sonner_examples %{
    "basic" => [],
    "with-description" => []
  }

  @message_scroller_chat [
    %{
      id: "msg-1",
      role: :user,
      text:
        "I'm building a chat for our app and the scroll behavior is driving me nuts. Every time the AI streams a reply, the whole thread jumps around."
    },
    %{
      id: "msg-2",
      role: :assistant,
      text:
        "That's the classic streaming scroll problem. Wrap your message list in `MessageScroller` and turn on `autoScroll` — the viewport pins to the bottom as tokens arrive, so users always see the latest text land in place.\n\nThe important part: it only auto-scrolls while the reader is already at the bottom. The moment they scroll up to read something earlier, auto-scroll backs off and their position is preserved. You get smooth streaming without fighting the user's intent."
    },
    %{
      id: "msg-3",
      role: :user,
      text:
        "Okay, but when someone sends a new message the view still feels jarring — like the whole conversation reloads from the top."
    },
    %{
      id: "msg-4",
      role: :assistant,
      text:
        "MessageScrollerItem fixes that with turn anchoring. Set `scrollAnchor` on the turn that should settle near the top instead of blindly snapping to the document bottom.\n\nIt also leaves a small peek of the previous exchange visible above the anchor, so context isn't lost. The reply starts in view without that disorienting jump you get from a plain overflow container."
    },
    %{
      id: "msg-5",
      role: :user,
      text:
        "And if they've scrolled up to re-read an older answer? I don't want to yank them back down."
    },
    %{
      id: "msg-6",
      role: :assistant,
      text:
        "You won't. Auto-scroll only runs when the viewport is already pinned to the bottom, so scrolling up is a deliberate opt-out — their place in the thread stays put even as new tokens keep arriving below.\n\nWhen there is content they haven't seen yet, `MessageScrollerButton` appears at the bottom of the viewport. One tap jumps them back to the newest message and re-engages auto-scroll. Same pattern as Slack or iMessage: quiet when you're caught up, helpful when you're not."
    },
    %{id: "msg-7", role: :user, text: "Last one — does this work with assistive tech?"},
    %{
      id: "msg-8",
      role: :assistant,
      text:
        "`MessageScrollerContent` sets `role=\"log\"` and `aria-relevant=\"additions\"` by default, so screen readers announce new messages as they stream in.\n\nThe scroll button is a real `<button>` with an sr-only label, and it's removed from the tab order when you're already at the bottom — no ghost focus stops."
    }
  ]

  @message_scroller_history [
    %{
      id: "history-1",
      role: :user,
      text: "Can you summarize the incident channel?"
    },
    %{
      id: "history-2",
      role: :assistant,
      text:
        "The first alert was a delayed export job. It started backing up around 09:42 UTC and triggered the warning once the retry queue crossed the threshold.\n\nNo customer-facing checkout paths were affected, but exports for larger workspaces were running about 12 minutes behind."
    },
    %{
      id: "history-3",
      role: :user,
      text: "Was checkout affected?"
    },
    %{
      id: "history-4",
      role: :assistant,
      text:
        "No checkout errors were reported. Payment authorization, order creation, and confirmation emails stayed inside their normal latency bands.\n\nThe only elevated metric was export queue depth, which maps to analytics downloads instead of checkout."
    },
    %{
      id: "history-5",
      role: :user,
      text: "What changed in the last deploy?"
    },
    %{
      id: "history-6",
      role: :assistant,
      text:
        "Only the export queue worker changed. The deploy moved large CSV jobs onto the shared retry policy, which made each failed attempt hold a worker slot longer than before.\n\nThe app deploy did not include checkout, pricing, or billing API changes."
    },
    %{
      id: "history-7",
      role: :user,
      text: "Do we need to roll back?"
    },
    %{
      id: "history-8",
      role: :assistant,
      text:
        "Not yet. Queue depth is recovering after we reduced retry concurrency, and the oldest pending job is now under five minutes old.\n\nKeep rollback ready if the queue starts climbing again, but the current trend points toward recovery."
    },
    %{
      id: "history-9",
      role: :user,
      text: "Keep watching for customer-visible issues."
    },
    %{
      id: "history-10",
      role: :assistant,
      text:
        "I will watch the queue and support tags for another 15 minutes. I am tracking export failures, delayed download requests, and any support thread that mentions missing reports.\n\nIf those stay quiet through the next batch window, we can close this as an internal degradation."
    }
  ]

  @message_scroller_opening_position [
    %{
      id: "open-1",
      role: :user,
      text: "This is the first message the user sent in the conversation."
    },
    %{
      id: "open-2",
      role: :assistant,
      text: "Workspace creation rose 8%, but first invite completion only rose 2%."
    },
    %{
      id: "open-3",
      role: :user,
      text: "This is the last message the user sent in the conversation."
    },
    %{
      id: "open-4",
      role: :assistant,
      text:
        "Start with the invite step. Teams are creating workspaces but waiting to add collaborators.\n\nRecommended follow-up:\n\n1. Compare invite drop-off by account size.\n2. Check whether users who skip invites still return within 24 hours.\n3. Review the empty-state copy on the first project screen.\n4. Segment activation by template, since template users may not need invites right away.\n\nIf that pattern holds, the next experiment should make collaboration useful earlier instead of prompting for invites harder."
    }
  ]

  @message_scroller_animation [
    %{
      id: "msg-1",
      role: :user,
      text: "Can user messages pop in like iMessage without breaking anchoring?"
    },
    %{
      id: "msg-2",
      role: :assistant,
      text:
        "Yes. Animate the user row with transform and opacity, and let the assistant response stream normally below it.\n\nThat keeps the row measurement predictable while still giving the newly sent bubble a more tactile entrance."
    },
    %{id: "msg-3", role: :user, text: "What makes the animation feel more like iMessage?"},
    %{
      id: "msg-4",
      role: :assistant,
      text:
        "Use a quick spring from the trailing edge: a little scale, a small upward move, and no layout animation.\n\nThe bubble feels tactile, but the measured row stays predictable, so anchoring and auto-scroll do not have to fight a changing layout."
    },
    %{
      id: "msg-5",
      role: :user,
      text: "Can I switch between presets while testing the same thread?"
    },
    %{
      id: "msg-6",
      role: :assistant,
      text:
        "Yes. Keep the conversation in place while you change the preset, then send the next message to compare the new entrance against the same context.\n\nThat makes it easier to judge the difference between a subtle fade, a snappy pop, and a more dramatic 3D tilt without rebuilding the scenario each time."
    }
  ]

  @message_scroller_commands [
    %{
      id: "command-activation",
      role: :user,
      text:
        "We're seeing activation dip after workspace creation. Can you help me find the likely step?"
    },
    %{
      id: "msg-1",
      role: :assistant,
      text:
        "The sharpest drop is between creating the workspace and inviting the first teammate.\n\nWorkspace creation is still healthy, but the invite step is where users pause. That suggests the product is asking for collaboration before the user has enough confidence in the workspace."
    },
    %{
      id: "command-compare",
      role: :user,
      text: "What should I compare before we change the onboarding flow?"
    },
    %{
      id: "msg-2",
      role: :assistant,
      text:
        "Compare three cohorts:\n\n1. Users who choose a template before inviting teammates.\n2. Users who start from a blank workspace.\n3. Users who skip invites and return within 24 hours.\n\nIf template users invite faster, the fix is probably better first-run guidance rather than a louder invite prompt."
    },
    %{id: "command-experiment", role: :user, text: "Can you turn that into an experiment?"},
    %{
      id: "msg-3",
      role: :assistant,
      text:
        "Yes. Create a variant that shows a short checklist after workspace creation:\n\n- Pick a template.\n- Add one project detail.\n- Invite a teammate when the workspace has context.\n\nMeasure first invite completion, 24-hour return rate, and whether teams create a second project."
    },
    %{id: "command-risk", role: :user, text: "What's the risk if we delay the invite prompt?"},
    %{
      id: "msg-4",
      role: :assistant,
      text:
        "The main risk is reducing team creation for accounts that already know who they want to invite.\n\nTo protect that path, keep the invite action visible in the header and only change the primary empty-state guidance. That gives confident teams a direct route without forcing uncertain users through the invite step too early."
    }
  ]

  @message_scroller_visibility [
    %{
      id: "vis-brief",
      role: :user,
      text: "Review the incident handoff and tell me what to read first."
    },
    %{
      id: "msg-1",
      role: :assistant,
      text:
        "Start with the summary and the impact section. The regression affected the upload queue, but the recovery path completed for every queued job."
    },
    %{id: "vis-impact", role: :user, text: "What was the customer impact?"},
    %{
      id: "msg-2",
      role: :assistant,
      text:
        "Impact was limited to delayed processing.\n\nNo records were dropped, and the reconciliation worker confirmed each retry batch. Support saw confusion from two customers, but there were no checkout or billing errors."
    },
    %{id: "vis-actions", role: :user, text: "What actions are open?"},
    %{
      id: "msg-3",
      role: :assistant,
      text:
        "Keep the retry window enabled until the next deploy, then add a queue-depth alert as the long-term fix.\n\nThe alert should fire on sustained queue growth, not a single short spike."
    },
    %{id: "vis-checklist", role: :user, text: "Give me the follow-up checklist."},
    %{
      id: "msg-4",
      role: :assistant,
      text:
        "After that, compare the queue recovery graph with the deploy timeline so the handoff shows exactly when processing returned to baseline. That makes it easier for support and engineering to answer the same customer questions without re-reading the whole incident thread.\n\nI would also add a short owner note beside each follow-up item. The checklist is small, but ownership keeps the retry-window decision, alert tuning, and support macro from drifting into separate follow-up conversations.\n\nKeep the retry window enabled until the next deploy, then add a queue-depth alert as the long-term fix.\n\nThe alert should fire on sustained queue growth, not a single short spike."
    }
  ]

  @message_scroller_anchoring [
    %{
      id: "anchor-1-user",
      role: :user,
      text: "Can you show me how anchoring behaves when a new prompt starts the turn?"
    },
    %{
      id: "anchor-1-assistant",
      role: :assistant,
      text:
        "Append the user prompt first, then append the assistant response. With User selected, the prompt settles near the top and the assistant response fills in below it."
    },
    %{
      id: "anchor-2-user",
      role: :user,
      text: "What changes when assistant messages are the anchor?"
    },
    %{
      id: "anchor-2-assistant",
      role: :assistant,
      text:
        "Now each assistant response is the item `MessageScroller` keeps in view. This is useful when the reply is the moment you want readers to land on after each turn."
    },
    %{id: "anchor-3-user", role: :user, text: "Can I switch roles and keep adding turns?"},
    %{
      id: "anchor-3-assistant",
      role: :assistant,
      text:
        "Yes. The next appended message with the selected role becomes the anchor, so you can compare user and assistant anchoring without resetting the demo."
    }
  ]

  @attachment_examples %{
    "default" => [
      %{
        id: "mountain-landscape",
        filename: "mountain-landscape.jpg",
        mediaType: "image/jpeg",
        type: "file",
        url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop"
      },
      %{
        id: "ocean-sunset",
        filename: "ocean-sunset.jpg",
        mediaType: "image/jpeg",
        type: "file",
        url: "https://images.unsplash.com/photo-1682687220742-aba13b6e50ba?w=400&h=400&fit=crop"
      },
      %{id: "document", filename: "document.pdf", mediaType: "application/pdf", type: "file"},
      %{id: "video", filename: "video.mp4", mediaType: "video/mp4", type: "file"}
    ],
    "list" => [
      %{
        id: "mountain-landscape",
        filename: "mountain-landscape.jpg",
        mediaType: "image/jpeg",
        type: "file",
        url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop"
      },
      %{
        id: "quarterly-report-2024",
        filename: "quarterly-report-2024.pdf",
        mediaType: "application/pdf",
        type: "file"
      },
      %{id: "product-demo", filename: "product-demo.mp4", mediaType: "video/mp4", type: "file"},
      %{
        id: "api-reference",
        filename: "api-reference",
        mediaType: "text/html",
        title: "API Documentation",
        type: "source-document"
      },
      %{
        id: "meeting-recording",
        filename: "meeting-recording.mp3",
        mediaType: "audio/mpeg",
        type: "file"
      }
    ],
    "inline" => [
      %{
        id: "mountain-landscape",
        filename: "mountain-landscape.jpg",
        mediaType: "image/jpeg",
        type: "file",
        url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop"
      },
      %{
        id: "quarterly-report",
        filename: "quarterly-report.pdf",
        mediaType: "application/pdf",
        type: "file"
      },
      %{
        id: "react-documentation",
        mediaType: "text/html",
        title: "React Documentation",
        type: "source-document"
      },
      %{
        id: "podcast-episode",
        filename: "podcast-episode.mp3",
        mediaType: "audio/mp3",
        type: "file"
      }
    ]
  }

  @bubble_collapsible_text """
  The accessibility review found two focus states that were visually too subtle in dark mode.

  I checked the dialog, menu, and drawer paths because each one renders focusable controls inside a layered surface.

  The dialog and drawer are fine. The menu needs the hover and focus tokens split so keyboard focus stays visible when the pointer is not involved.

  I also recommend keeping the change in the style file instead of the primitive so the other themes can choose their own focus treatment later.
  """
  @bubble_collapsible_preview String.slice(@bubble_collapsible_text, 0, 180) <> "..."

  @card_spacing_classes %{
    "4" => "[--card-spacing:--spacing(4)]",
    "5" => "[--card-spacing:--spacing(5)]",
    "6" => "[--card-spacing:--spacing(6)]",
    "8" => "[--card-spacing:--spacing(8)]"
  }

  @attachment_images [
    %{
      name: "workspace.png",
      meta: "PNG · 820 KB",
      src:
        "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80",
      alt: "Workspace"
    },
    %{
      name: "desk-reference.jpg",
      meta: "JPG · 1.1 MB",
      src:
        "https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=900&auto=format&fit=crop&q=80",
      alt: "Desk"
    },
    %{
      name: "office-reference.jpg",
      meta: "JPG · 940 KB",
      src:
        "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=900&auto=format&fit=crop&q=80",
      alt: "Office"
    }
  ]

  @attachment_group_items [
    %{name: "briefing-notes.pdf", meta: "PDF · 1.4 MB", icon: "file-text"},
    %{
      name: "workspace.png",
      meta: "PNG · 820 KB",
      src:
        "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80"
    },
    %{name: "customers.csv", meta: "CSV · 18 KB", icon: "table"},
    %{name: "renderer.tsx", meta: "TSX · 12 KB", icon: "file-code"}
  ]

  @select_fruits [
    %{label: "Apple", value: "apple"},
    %{label: "Banana", value: "banana"},
    %{label: "Blueberry", value: "blueberry"},
    %{label: "Grapes", value: "grapes"},
    %{label: "Pineapple", value: "pineapple"}
  ]

  @select_timezones [
    {"North America",
     [
       %{label: "Eastern Standard Time", value: "est"},
       %{label: "Central Standard Time", value: "cst"},
       %{label: "Mountain Standard Time", value: "mst"},
       %{label: "Pacific Standard Time", value: "pst"},
       %{label: "Alaska Standard Time", value: "akst"},
       %{label: "Hawaii Standard Time", value: "hst"}
     ]},
    {"Europe & Africa",
     [
       %{label: "Greenwich Mean Time", value: "gmt"},
       %{label: "Central European Time", value: "cet"},
       %{label: "Eastern European Time", value: "eet"},
       %{label: "Western European Summer Time", value: "west"},
       %{label: "Central Africa Time", value: "cat"},
       %{label: "East Africa Time", value: "eat"}
     ]},
    {"Asia",
     [
       %{label: "Moscow Time", value: "msk"},
       %{label: "India Standard Time", value: "ist"},
       %{label: "China Standard Time", value: "cst_china"},
       %{label: "Japan Standard Time", value: "jst"},
       %{label: "Korea Standard Time", value: "kst"},
       %{label: "Indonesia Central Standard Time", value: "ist_indonesia"}
     ]},
    {"Australia & Pacific",
     [
       %{label: "Australian Western Standard Time", value: "awst"},
       %{label: "Australian Central Standard Time", value: "acst"},
       %{label: "Australian Eastern Standard Time", value: "aest"},
       %{label: "New Zealand Standard Time", value: "nzst"},
       %{label: "Fiji Time", value: "fjt"}
     ]},
    {"South America",
     [
       %{label: "Argentina Time", value: "art"},
       %{label: "Bolivia Time", value: "bot"},
       %{label: "Brasilia Time", value: "brt"},
       %{label: "Chile Standard Time", value: "clt"}
     ]}
  ]

  # These lists are copied from the twelve pinned shadcn Combobox examples.
  # Keep their order: Base UI uses this order for keyboard navigation.
  @combobox_frameworks ["Next.js", "SvelteKit", "Nuxt.js", "Remix", "Astro"]
  @combobox_rtl_categories [
    "technology",
    "design",
    "business",
    "marketing",
    "education",
    "health"
  ]

  @combobox_timezones [
    %{
      label: "Americas",
      items: [
        "(GMT-5) New York",
        "(GMT-8) Los Angeles",
        "(GMT-6) Chicago",
        "(GMT-5) Toronto",
        "(GMT-8) Vancouver",
        "(GMT-3) São Paulo"
      ]
    },
    %{
      label: "Europe",
      items: [
        "(GMT+0) London",
        "(GMT+1) Paris",
        "(GMT+1) Berlin",
        "(GMT+1) Rome",
        "(GMT+1) Madrid",
        "(GMT+1) Amsterdam"
      ]
    },
    %{
      label: "Asia/Pacific",
      items: [
        "(GMT+9) Tokyo",
        "(GMT+8) Shanghai",
        "(GMT+8) Singapore",
        "(GMT+4) Dubai",
        "(GMT+11) Sydney",
        "(GMT+9) Seoul"
      ]
    }
  ]

  @combobox_countries [
    %{code: "", value: "", label: "Select country", continent: ""},
    %{code: "ar", value: "argentina", label: "Argentina", continent: "South America"},
    %{code: "au", value: "australia", label: "Australia", continent: "Oceania"},
    %{code: "br", value: "brazil", label: "Brazil", continent: "South America"},
    %{code: "ca", value: "canada", label: "Canada", continent: "North America"},
    %{code: "cn", value: "china", label: "China", continent: "Asia"},
    %{code: "co", value: "colombia", label: "Colombia", continent: "South America"},
    %{code: "eg", value: "egypt", label: "Egypt", continent: "Africa"},
    %{code: "fr", value: "france", label: "France", continent: "Europe"},
    %{code: "de", value: "germany", label: "Germany", continent: "Europe"},
    %{code: "it", value: "italy", label: "Italy", continent: "Europe"},
    %{code: "jp", value: "japan", label: "Japan", continent: "Asia"},
    %{code: "ke", value: "kenya", label: "Kenya", continent: "Africa"},
    %{code: "mx", value: "mexico", label: "Mexico", continent: "North America"},
    %{code: "nz", value: "new-zealand", label: "New Zealand", continent: "Oceania"},
    %{code: "ng", value: "nigeria", label: "Nigeria", continent: "Africa"},
    %{code: "za", value: "south-africa", label: "South Africa", continent: "Africa"},
    %{code: "kr", value: "south-korea", label: "South Korea", continent: "Asia"},
    %{code: "gb", value: "united-kingdom", label: "United Kingdom", continent: "Europe"},
    %{code: "us", value: "united-states", label: "United States", continent: "North America"}
  ]

  defp assign_combobox_example_data(assigns) do
    assigns
    |> assign(:combobox_frameworks, @combobox_frameworks)
    |> assign(:combobox_timezones, @combobox_timezones)
    |> assign(:combobox_countries, @combobox_countries)
    |> assign(:combobox_rtl_categories, @combobox_rtl_categories)
  end

  @collapsible_file_tree [
                           %{
                             name: "components",
                             items: [
                               %{
                                 name: "ui",
                                 items:
                                   Enum.map(
                                     ~w(button.tsx card.tsx dialog.tsx input.tsx select.tsx table.tsx),
                                     &%{name: &1}
                                   )
                               },
                               %{name: "login-form.tsx"},
                               %{name: "register-form.tsx"}
                             ]
                           },
                           %{
                             name: "lib",
                             items: Enum.map(~w(utils.ts cn.ts api.ts), &%{name: &1})
                           },
                           %{
                             name: "hooks",
                             items:
                               Enum.map(
                                 ~w(use-media-query.ts use-debounce.ts use-local-storage.ts),
                                 &%{name: &1}
                               )
                           },
                           %{
                             name: "types",
                             items: Enum.map(~w(index.d.ts api.d.ts), &%{name: &1})
                           },
                           %{
                             name: "public",
                             items: Enum.map(~w(favicon.ico logo.svg images), &%{name: &1})
                           }
                         ] ++
                           Enum.map(
                             ~w(app.tsx layout.tsx globals.css package.json tsconfig.json README.md .gitignore),
                             &%{name: &1}
                           )

  @navigation_components [
    %{
      title: "Alert Dialog",
      href: "/docs/primitives/alert-dialog",
      description:
        "A modal dialog that interrupts the user with important content and expects a response."
    },
    %{
      title: "Hover Card",
      href: "/docs/primitives/hover-card",
      description: "For sighted users to preview content available behind a link."
    },
    %{
      title: "Progress",
      href: "/docs/primitives/progress",
      description:
        "Displays an indicator showing the completion progress of a task, typically displayed as a progress bar."
    },
    %{
      title: "Scroll-area",
      href: "/docs/primitives/scroll-area",
      description: "Visually or semantically separates content."
    },
    %{
      title: "Tabs",
      href: "/docs/primitives/tabs",
      description:
        "A set of layered sections of content—known as tab panels—that are displayed one at a time."
    },
    %{
      title: "Tooltip",
      href: "/docs/primitives/tooltip",
      description:
        "A popup that displays information related to an element when the element receives keyboard focus or the mouse hovers over it."
    }
  ]

  @navigation_components_rtl [
    %{
      title: "حوار التنبيه",
      href: "/docs/primitives/alert-dialog",
      description: "حوار نافذة يقطع المستخدم بمحتوى مهم ويتوقع استجابة."
    },
    %{
      title: "بطاقة التحويم",
      href: "/docs/primitives/hover-card",
      description: "للمستخدمين المبصرين لمعاينة المحتوى المتاح خلف الرابط."
    },
    %{
      title: "التقدم",
      href: "/docs/primitives/progress",
      description: "يعرض مؤشرًا يوضح تقدم إتمام المهمة، عادةً يتم عرضه كشريط تقدم."
    },
    %{
      title: "منطقة التمرير",
      href: "/docs/primitives/scroll-area",
      description: "يفصل المحتوى بصريًا أو دلاليًا."
    },
    %{
      title: "التبويبات",
      href: "/docs/primitives/tabs",
      description:
        "مجموعة من أقسام المحتوى المتعددة الطبقات—المعروفة بألواح التبويب—التي يتم عرضها واحدة في كل مرة."
    },
    %{
      title: "تلميح",
      href: "/docs/primitives/tooltip",
      description:
        "نافذة منبثقة تعرض معلومات متعلقة بعنصر عندما يتلقى العنصر التركيز على لوحة المفاتيح أو عند تحويم الماوس فوقه."
    }
  ]

  @field_months [
    %{label: "MM", value: ""},
    %{label: "01", value: "01"},
    %{label: "02", value: "02"},
    %{label: "03", value: "03"},
    %{label: "04", value: "04"},
    %{label: "05", value: "05"},
    %{label: "06", value: "06"},
    %{label: "07", value: "07"},
    %{label: "08", value: "08"},
    %{label: "09", value: "09"},
    %{label: "10", value: "10"},
    %{label: "11", value: "11"},
    %{label: "12", value: "12"}
  ]

  @field_years [
    %{label: "YYYY", value: ""},
    %{label: "2024", value: "2024"},
    %{label: "2025", value: "2025"},
    %{label: "2026", value: "2026"},
    %{label: "2027", value: "2027"},
    %{label: "2028", value: "2028"},
    %{label: "2029", value: "2029"}
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

  @doc "The empty toast lists used by the three official examples."
  def toast_examples, do: @toast_examples

  @doc """
  What a page assigns before it renders an example.

  Three places render one — the index, the preview, and `mix snapshot` — and an
  example that reads an assign has to find it in all three.

  `show_values` is the environment variables example's, and it is an assign for
  the reason that component exists: the value it reveals is a secret, so the
  server decides when the page is given it.
  """
  def page_assigns(options \\ []) do
    reference_date = Keyword.get(options, :reference_date, Date.utc_today())

    %{
      toast_examples: @toast_examples,
      toast_sequence: 0,
      sonner_examples: @sonner_examples,
      sonner_sequence: 0,
      bubble_toasts: [],
      bubble_sequence: 0,
      show_values: false,
      card_spacing: "4",
      field_switch_checked: false,
      field_slider_values: [200, 800],
      slider_controlled_values: [0.3, 0.7],
      progress_demo_value: 13,
      progress_value: 50,
      select_align_item: true,
      questionnaire_controlled_item: "scope",
      questionnaire_runtime: "local",
      questionnaire_shortcuts: "letters",
      questionnaire_validation_item: "detail",
      questionnaire_validation_errors: %{},
      questionnaire_navigation_item: "permission",
      questionnaire_navigation_statuses: %{
        "permission" => "unanswered",
        "verification" => "unanswered"
      },
      question_answers: %{},
      chart_demo_series: "desktop",
      data_table: %{
        filter: "",
        selected: [],
        sort: nil,
        visible: ["status", "email", "amount"]
      },
      date_picker: %{
        "default" => nil,
        "basic" => nil,
        "range" => %{
          from: date_picker_year_date(reference_date, 1, 20),
          to: Date.add(date_picker_year_date(reference_date, 1, 20), 20)
        },
        "dob" => nil,
        "input" => ~D[2025-06-01],
        "time" => nil,
        "natural-language" => Date.add(reference_date, 2),
        "rtl" => nil
      },
      date_picker_reference_date: reference_date,
      calendar_reference_date: reference_date,
      date_picker_values: %{
        "input" => "June 01, 2025",
        "natural-language" => "In 2 days"
      },
      date_picker_selection_versions: %{
        "input" => 0,
        "natural-language" => 0
      },
      attachment_examples: @attachment_examples,
      message_scroller: %{
        default: [],
        default_busy: false,
        previous_context: Enum.take(@message_scroller_chat, 2),
        previous_context_busy: false,
        previous_context_peek: 64,
        anchoring: [],
        anchoring_role: :user,
        anchoring_index: 0,
        group_turn: :idle,
        group_generation: 0,
        streaming: [],
        streaming_busy: false,
        animation: [],
        animation_busy: false,
        animation_preset: "fade",
        load_history: 5,
        load_history_generation: 0,
        previous_context_generation: 0,
        opening_position: "last-anchor"
      },
      calendar_presets_date: calendar_year_date(reference_date, 2, 12),
      calendar_presets_month: calendar_month_start(reference_date),
      sidebar_active_team: "acme-inc"
    }
  end

  @data_table_payments [
    %{id: "m5gr84i9", amount: 316, status: "success", email: "ken99@example.com"},
    %{id: "3u1reuv4", amount: 242, status: "success", email: "Abe45@example.com"},
    %{id: "derv1ws0", amount: 837, status: "processing", email: "Monserrat44@example.com"},
    %{id: "5kma53ae", amount: 874, status: "success", email: "Silas22@example.com"},
    %{id: "bhqecj4p", amount: 721, status: "failed", email: "carmella@example.com"}
  ]

  @doc false
  def data_table_payments(state) do
    filter = state.filter |> String.downcase() |> String.trim()

    @data_table_payments
    |> Enum.filter(fn payment ->
      filter == "" or String.contains?(String.downcase(payment.email), filter)
    end)
    |> sort_data_table(state.sort)
  end

  @doc false
  def data_table_event(state, "filter", %{"filter" => filter}) when is_binary(filter),
    do: %{state | filter: filter}

  def data_table_event(state, "sort", _params) do
    sort = if state.sort == :asc, do: :desc, else: :asc
    %{state | sort: sort}
  end

  def data_table_event(state, "toggle-row", %{"id" => id}) do
    selected =
      if id in state.selected, do: List.delete(state.selected, id), else: state.selected ++ [id]

    %{state | selected: selected}
  end

  def data_table_event(state, "toggle-all", _params) do
    ids = data_table_payments(state) |> Enum.map(& &1.id)

    selected =
      if ids != [] and Enum.all?(ids, &(&1 in state.selected)),
        do: state.selected -- ids,
        else: Enum.uniq(state.selected ++ ids)

    %{state | selected: selected}
  end

  def data_table_event(state, "toggle-column", %{"column" => column})
      when column in ["status", "email", "amount"] do
    visible =
      if column in state.visible,
        do: List.delete(state.visible, column),
        else: state.visible ++ [column]

    %{state | visible: visible}
  end

  def data_table_event(state, _event, _params), do: state

  defp sort_data_table(payments, :asc), do: Enum.sort_by(payments, &String.downcase(&1.email))

  defp sort_data_table(payments, :desc),
    do: Enum.sort_by(payments, &String.downcase(&1.email), :desc)

  defp sort_data_table(payments, _sort), do: payments

  @doc false
  def sidebar_team?(id), do: Enum.any?(sidebar_teams(), &(sidebar_team_id(&1) == id))

  defp sidebar_team(id) do
    Enum.find(sidebar_teams(), &(sidebar_team_id(&1) == id)) || hd(sidebar_teams())
  end

  defp sidebar_team_id(team),
    do: String.replace(String.downcase(team.name), ~r/[^a-z]+/, "-")

  @doc false
  def message_scroller_event(%{default_busy: true} = state, "send", "default"), do: state

  def message_scroller_event(state, "send", "default") do
    %{state | default: state.default ++ [next_row(state.default)], default_busy: true}
  end

  def message_scroller_event(%{default_busy: true} = state, "default-reply", "default") do
    %{state | default: state.default ++ [next_row(state.default)], default_busy: false}
  end

  def message_scroller_event(state, "default-reply", "default"), do: state

  def message_scroller_event(%{streaming_busy: true} = state, "send", "streaming"), do: state

  def message_scroller_event(state, "send", "streaming") do
    %{state | streaming: state.streaming ++ [next_row(state.streaming)], streaming_busy: true}
  end

  def message_scroller_event(%{streaming_busy: true} = state, "stream-reply", "streaming") do
    %{state | streaming: state.streaming ++ [next_row(state.streaming)], streaming_busy: false}
  end

  def message_scroller_event(state, "stream-reply", "streaming"), do: state
  def message_scroller_event(%{animation_busy: true} = state, "send", "animation"), do: state

  def message_scroller_event(state, "send", "animation") do
    %{state | animation: state.animation ++ [next_row(state.animation)], animation_busy: true}
  end

  def message_scroller_event(%{animation_busy: true} = state, "animation-reply", "animation") do
    %{state | animation: state.animation ++ [next_row(state.animation)], animation_busy: false}
  end

  def message_scroller_event(state, "animation-reply", "animation"), do: state

  def message_scroller_event(%{previous_context_busy: true} = state, "send", "previous-context"),
    do: state

  def message_scroller_event(state, "send", "previous-context") do
    if length(state.previous_context) >= length(@message_scroller_chat) do
      state
    else
      %{
        state
        | previous_context:
            state.previous_context ++
              [Enum.at(@message_scroller_chat, length(state.previous_context))],
          previous_context_busy: true
      }
    end
  end

  def message_scroller_event(
        %{previous_context_busy: true} = state,
        "previous-context-reply",
        "previous-context"
      ) do
    if length(state.previous_context) >= length(@message_scroller_chat) do
      %{state | previous_context_busy: false}
    else
      %{
        state
        | previous_context:
            state.previous_context ++
              [Enum.at(@message_scroller_chat, length(state.previous_context))],
          previous_context_busy: false
      }
    end
  end

  def message_scroller_event(state, "previous-context-reply", "previous-context"), do: state

  def message_scroller_event(state, "send", "anchoring"),
    do: %{
      state
      | anchoring_index: min(state.anchoring_index + 1, length(@message_scroller_anchoring))
    }

  def message_scroller_event(state, "reset", "default"),
    do: %{state | default: [], default_busy: false}

  def message_scroller_event(state, "reset", "streaming"),
    do: %{state | streaming: [], streaming_busy: false}

  def message_scroller_event(state, "reset", "animation"),
    do: %{state | animation: [], animation_busy: false}

  def message_scroller_event(state, "reset", "previous-context"),
    do: %{
      state
      | previous_context: Enum.take(@message_scroller_chat, 2),
        previous_context_busy: false,
        previous_context_peek: 64,
        previous_context_generation: state.previous_context_generation + 1
    }

  def message_scroller_event(state, "reset", "load-history"),
    do: %{
      state
      | load_history: 5,
        load_history_generation: state.load_history_generation + 1
    }

  def message_scroller_event(state, "reset", "anchoring"),
    do: %{state | anchoring_index: 0, anchoring: []}

  def message_scroller_event(state, "reset", "group-chat") do
    %{state | group_turn: :idle, group_generation: state.group_generation + 1}
  end

  def message_scroller_event(state, "group-next", _example),
    do: %{state | group_turn: if(state.group_turn == :idle, do: :marker, else: :message)}

  def message_scroller_event(state, "load-history", _example),
    do: %{state | load_history: length(@message_scroller_history)}

  def message_scroller_event(state, "previous-context-peek", value)
      when is_integer(value) and value in 64..128,
      do: %{state | previous_context_peek: value}

  def message_scroller_event(state, "opening-position", value)
      when value in ["start", "end", "last-anchor"],
      do: %{state | opening_position: value}

  def message_scroller_event(state, "anchor-role", "assistant"),
    do: %{state | anchoring_role: :assistant, anchoring_index: 0, anchoring: []}

  def message_scroller_event(state, "anchor-role", "user"),
    do: %{state | anchoring_role: :user, anchoring_index: 0, anchoring: []}

  def message_scroller_event(state, "animation-preset", preset)
      when preset in [
             "fade",
             "slide-up",
             "slide-side",
             "pop",
             "spring-bounce",
             "blur-fade",
             "scale-fade"
           ],
      do: %{state | animation_preset: preset}

  def message_scroller_event(state, _event, _example), do: state

  defp next_row(rows), do: length(rows) + 1

  defp next_chat_user(messages) do
    @message_scroller_chat
    |> Enum.drop(length(messages))
    |> Enum.find(&(&1.role == :user))
  end

  @doc "Builds the exact notice for the Load History example."
  def message_scroller_history_notice(id),
    do: %{
      id: id,
      type: nil,
      title: "History loaded",
      description: "Scroll up to see earlier messages."
    }

  @doc "Removes one attachment from one official attachment example."
  def remove_attachment(attachment_examples, example, id) do
    Map.update!(attachment_examples, example, fn attachments ->
      Enum.reject(attachments, &(&1.id == id))
    end)
  end

  @doc "Adds one toast to an official example list."
  def add_toast(toast_examples, example, toast) do
    Map.update!(toast_examples, example, &(&1 ++ [toast]))
  end

  @doc "Builds the message for one official Toast action."
  def toast_notice("default", _type, id) do
    %{
      id: id,
      type: nil,
      title: "Event created",
      description: "Sunday, December 3 at 9:00 AM",
      action_label: "Undo"
    }
  end

  def toast_notice("types", type, id) do
    descriptions = %{
      nil => "Event has been created.",
      "success" => "Event has been created.",
      "info" => "Arrive 10 minutes before the event.",
      "warning" => "The event cannot start before 8:00 AM.",
      "error" => "The event could not be created."
    }

    %{
      id: id,
      type: type,
      priority: if(type == "error", do: "high"),
      title: nil,
      description: Map.fetch!(descriptions, type)
    }
  end

  def toast_notice("marker", _type, id) do
    %{
      id: id,
      type: nil,
      title: nil,
      description: "You clicked the revert button"
    }
  end

  @doc "Builds the result message for one official Questionnaire submission."
  def questionnaire_notice("card", params, id) do
    %{
      id: id,
      type: nil,
      title: "Agent task created",
      description: "Task: #{params["task"] || "None"} · Handoff: #{params["output"] || "None"}"
    }
  end

  def questionnaire_notice("dialog", params, id) do
    %{
      id: id,
      type: nil,
      title: "Clarification sent",
      description:
        "Scope: #{params["scope"] || "None"} · Verification: #{params["tests"] || "None"}"
    }
  end

  @doc "Builds the loading message for the official Promise example."
  def toast_promise_loading(id) do
    %{id: id, type: "loading", title: nil, description: "Creating event…"}
  end

  @doc "Builds the completed message for the official Promise example."
  def toast_promise_complete(id) do
    %{id: id, type: "success", title: nil, description: "Event created."}
  end

  @doc "Replaces one toast in an official example list."
  def replace_toast(toast_examples, example, id, replacement) do
    Map.update!(toast_examples, example, fn toasts ->
      Enum.map(toasts, fn toast -> if toast.id == id, do: replacement, else: toast end)
    end)
  end

  @doc "Removes the toast whose browser id the component sent."
  def dismiss_toast(toast_examples, id) do
    Map.new(toast_examples, fn {example, toasts} ->
      toaster = "toast-#{example}"
      {example, Enum.reject(toasts, &(LiveBase.Toast.toast_id(toaster, &1.id) == id))}
    end)
  end

  @doc "Builds the message for one pinned Sonner action."
  def sonner_notice("basic", id),
    do: %{id: id, type: nil, title: "Event has been created", description: nil}

  def sonner_notice("with-description", id),
    do: %{
      id: id,
      type: nil,
      title: "Event has been created",
      description: "Monday, January 3rd at 6:00pm"
    }

  @doc "Adds one message to a pinned Sonner example."
  def add_sonner_toast(sonner_examples, example, toast) do
    Map.update!(sonner_examples, example, &(&1 ++ [toast]))
  end

  @doc "Removes a Sonner message from the list that owns it."
  def dismiss_sonner_toast(sonner_examples, id) do
    Map.new(sonner_examples, fn {example, toasts} ->
      toaster = "sonner-#{example}"
      {example, Enum.reject(toasts, &(LiveBase.Toast.toast_id(toaster, &1.id) == id))}
    end)
  end

  @doc "Builds one message for the official Bubble button examples."
  def bubble_notice("forgot-password", id),
    do: %{id: id, title: "You clicked forgot password", description: nil}

  def bubble_notice("subscription", id),
    do: %{id: id, title: "You clicked help with subscription", description: nil}

  def bubble_notice("human", id),
    do: %{id: id, title: "You clicked something else. Talk to a human.", description: nil}

  def bubble_notice("run-command", id),
    do: %{id: id, type: "success", title: "You clicked yes, running command...", description: nil}

  @doc "Adds one Bubble notice."
  def add_bubble_notice(toasts, toast), do: toasts ++ [toast]

  @doc "Removes one Bubble notice."
  def dismiss_bubble_notice(toasts, id) do
    Enum.reject(toasts, &(LiveBase.Toast.toast_id("bubble-toasts", &1.id) == id))
  end

  @doc "Returns the Card spacing class for an official spacing value."
  def card_spacing_class(value), do: Map.fetch!(@card_spacing_classes, value)

  @doc "Updates one official Date Picker selection from the Calendar event contract."
  def date_picker_select(state, example, selected)
      when example in ~w(default basic dob input time natural-language rtl) do
    case selected do
      "" ->
        Map.put(state, example, nil)

      value ->
        case Date.from_iso8601(value) do
          {:ok, date} -> Map.put(state, example, date)
          {:error, _} -> state
        end
    end
  end

  def date_picker_select(state, "range", selected) do
    case String.split(selected, "/", parts: 2) do
      [from, to] ->
        with {:ok, from} <- Date.from_iso8601(from),
             {:ok, to} <- date_picker_optional_date(to) do
          Map.put(state, "range", %{from: from, to: to})
        else
          _ -> state
        end

      _ ->
        state
    end
  end

  def date_picker_select(state, _example, _selected), do: state

  @doc "Updates the text field state for the two official typed Date Pickers."
  def date_picker_input(state, example, value) when example in ~w(input natural-language) do
    date = date_picker_parse(value, state[example])
    Map.put(state, example, date)
  end

  def date_picker_input(state, _example, _value), do: state

  @doc "Keeps the typed text and parsed date for an official Date Picker input."
  def date_picker_input_change(state, values, example, value) do
    {date_picker_input(state, example, value), Map.put(values, example, value)}
  end

  @doc "Formats typed Date Picker text after a calendar choice."
  def date_picker_selection_values(values, state, example)
      when example in ~w(input natural-language) do
    Map.put(values, example, date_picker_input_value(state[example]))
  end

  def date_picker_selection_values(values, _state, _example), do: values

  @doc "Marks a typed Date Picker value that came from a calendar selection."
  def date_picker_selection_versions(versions, example)
      when example in ~w(input natural-language) do
    Map.update(versions, example, 1, &(&1 + 1))
  end

  def date_picker_selection_versions(versions, _example), do: versions

  defp date_picker_optional_date(""), do: {:ok, nil}
  defp date_picker_optional_date(value), do: Date.from_iso8601(value)

  defp date_picker_parse(value, fallback) do
    normalized = String.downcase(String.trim(value))

    cond do
      normalized == "tomorrow" ->
        Date.add(Date.utc_today(), 1)

      normalized == "next week" ->
        Date.add(Date.utc_today(), 7)

      String.starts_with?(normalized, "next ") ->
        date_picker_next_weekday(normalized)

      Regex.match?(~r/^in \d+ days?$/, normalized) ->
        [_, days] = Regex.run(~r/^in (\d+) days?$/, normalized)
        Date.add(Date.utc_today(), String.to_integer(days))

      true ->
        parse_long_date(value) || fallback
    end
  end

  defp parse_long_date(value) do
    case Regex.run(~r/^([A-Za-z]+) (\d{1,2}), (\d{4})$/, String.trim(value)) do
      [_, month, day, year] ->
        with {month, ""} <- Integer.parse(month_number(month)),
             {day, ""} <- Integer.parse(day),
             {year, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year, month, day),
             do: date

      _ ->
        nil
    end
  end

  defp date_picker_next_weekday("next " <> weekday) do
    weekdays = %{
      "monday" => 1,
      "tuesday" => 2,
      "wednesday" => 3,
      "thursday" => 4,
      "friday" => 5,
      "saturday" => 6,
      "sunday" => 7
    }

    case Map.get(weekdays, weekday) do
      nil ->
        nil

      target ->
        offset = rem(target - Date.day_of_week(Date.utc_today()) + 6, 7) + 1
        Date.add(Date.utc_today(), offset)
    end
  end

  defp month_number(month) do
    case Enum.find_index(
           ~w(January February March April May June July August September October November December),
           &(&1 == month)
         ) do
      nil -> "0"
      index -> Integer.to_string(index + 1)
    end
  end

  @doc "Every component that has examples, in the order they are listed."
  def components do
    ~w(accordion alert alert-dialog aspect-ratio attachment avatar badge breadcrumb bubble button calendar date-picker carousel
       button-group card chart checkbox collapsible combobox command context-menu dialog drawer dropdown-menu empty hover-card input item kbd label marker menubar
       input-group input-otp message-scroller native-select navigation-menu pagination popover progress radio-group resizable scroll-area select separator sheet skeleton slider spinner switch table data-table tabs task sources suggestion checkpoint confirmation chain-of-thought reasoning package-info field textarea toggle tooltip
       toggle-group question questionnaire sidebar snippet sonner toast shadcn-message ai_elements-message
       artifact attachments commit environment-variables image mic-selector model-selector plan
       queue speech-input transcription voice-selector
       inline-citation stack-trace test-results tool web-preview
       agent audio-player code-block context conversation file-tree prompt-input
       sandbox schema-display shimmer terminal
       connection controls edge jsx-preview node panel persona toolbar
       open-in-chat typography)
  end

  @doc "The examples for a component."
  def all("accordion") do
    [
      one("default", "Default", "The official accordion example.", &accordion_default/1),
      one("basic", "Basic", "The official basic example.", &accordion_basic/1),
      one("multiple", "Multiple", "The official multiple-panel example.", &accordion_multiple/1),
      one("disabled", "Disabled", "The official disabled item example.", &accordion_disabled/1),
      one("borders", "Borders", "The official bordered example.", &accordion_borders/1),
      one("card", "Card", "The official card example.", &accordion_card/1),
      one("rtl", "Right to left", "The official Arabic example.", &accordion_rtl/1)
    ]
  end

  def all("carousel") do
    [
      one("default", "Default", "The pinned official carousel example.", &carousel_default/1),
      one("size", "Size", "The pinned official carousel size example.", &carousel_size/1),
      one(
        "spacing",
        "Spacing",
        "The pinned official carousel spacing example.",
        &carousel_spacing/1
      ),
      one(
        "orientation",
        "Orientation",
        "The pinned official vertical carousel example.",
        &carousel_orientation/1
      ),
      one("api", "API", "The pinned official carousel API example.", &carousel_api/1),
      one(
        "plugin",
        "Plugin",
        "The pinned official autoplay carousel example.",
        &carousel_plugin/1
      ),
      one("rtl", "Right to left", "The pinned official Arabic example.", &carousel_rtl/1)
    ]
  end

  def all("calendar") do
    [
      one("default", "Default", "The pinned official Calendar example.", &calendar_default/1),
      one("hijri", "Hijri", "The pinned Persian Calendar example.", &calendar_hijri/1),
      one("basic", "Basic", "The pinned unselected Calendar example.", &calendar_basic/1),
      one("multiple", "Multiple", "The pinned multiple-date Calendar.", &calendar_multiple/1),
      one("range", "Range", "The pinned two-month range Calendar.", &calendar_range/1),
      one("caption", "Caption", "The pinned Calendar caption controls.", &calendar_caption/1),
      one("presets", "Presets", "The pinned Calendar preset actions.", &calendar_presets/1),
      one("time", "Time", "The pinned Calendar time controls.", &calendar_time/1),
      one(
        "booked-dates",
        "Booked dates",
        "The pinned booked-date Calendar.",
        &calendar_booked_dates/1
      ),
      one(
        "custom-days",
        "Custom days",
        "The pinned Calendar day prices.",
        &calendar_custom_days/1
      ),
      one(
        "week-numbers",
        "Week numbers",
        "The pinned Calendar week numbers.",
        &calendar_week_numbers/1
      ),
      one("rtl", "Right to left", "The pinned Arabic Calendar.", &calendar_rtl/1)
    ]
  end

  def all("date-picker") do
    [
      one("default", "Default", "The pinned official Date Picker example.", &date_picker_demo/1),
      one("basic", "Basic", "The pinned official basic Date Picker.", &date_picker_basic/1),
      one("range", "Range", "The pinned official Date Picker range.", &date_picker_range/1),
      one(
        "dob",
        "Date of birth",
        "The pinned official date of birth picker.",
        &date_picker_dob/1
      ),
      one("input", "Input", "The pinned official input Date Picker.", &date_picker_input/1),
      one("time", "Time", "The pinned official Date Picker with time.", &date_picker_time/1),
      one(
        "natural-language",
        "Natural language",
        "The pinned official natural language Date Picker.",
        &date_picker_natural_language/1
      ),
      one("rtl", "Right to left", "The pinned official Arabic Date Picker.", &date_picker_rtl/1)
    ]
  end

  def all("chart") do
    [
      one(
        "demo",
        "Interactive chart",
        "The official interactive bar chart example.",
        &chart_demo/1
      ),
      one("example", "Chart", "The official bar chart example.", &chart_example/1),
      one("example-grid", "Grid", "The official chart grid example.", &chart_example_grid/1),
      one("example-axis", "Axis", "The official chart axis example.", &chart_example_axis/1),
      one(
        "example-tooltip",
        "Tooltip",
        "The official interactive chart tooltip example.",
        &chart_example_tooltip/1
      ),
      one(
        "example-legend",
        "Legend",
        "The official chart legend example.",
        &chart_example_legend/1
      ),
      one(
        "tooltip",
        "Tooltip anatomy",
        "The official tooltip anatomy example.",
        &chart_tooltip/1
      ),
      one("rtl", "Right to left", "The official Arabic chart example.", &chart_rtl/1)
    ]
  end

  def all("alert") do
    [
      one("default", "Default", "The pinned official alert example.", &alert_default/1),
      one("basic", "Basic", "The pinned official basic alert example.", &alert_basic/1),
      one(
        "destructive",
        "Destructive",
        "The pinned official destructive alert example.",
        &alert_destructive/1
      ),
      one(
        "action",
        "Action",
        "The pinned official alert action example.",
        &alert_action_example/1
      ),
      one("colors", "Colors", "The pinned official alert color example.", &alert_colors/1),
      one("rtl", "Right to left", "The pinned official RTL alert example.", &alert_rtl/1)
    ]
  end

  def all("alert-dialog") do
    [
      one(
        "default",
        "Default",
        "The official alert dialog example.",
        &alert_dialog_default/1
      ),
      one("basic", "Basic", "The official alert dialog example.", &alert_dialog_basic/1),
      one("small", "Small", "The official small alert dialog.", &alert_dialog_small/1),
      one("media", "Media", "The official alert dialog with media.", &alert_dialog_media/1),
      one(
        "small-media",
        "Small media",
        "The official small alert dialog with media.",
        &alert_dialog_small_media/1
      ),
      one(
        "destructive",
        "Destructive",
        "The official destructive alert dialog.",
        &alert_dialog_destructive/1
      ),
      one("rtl", "Right to left", "The official RTL alert dialogs.", &alert_dialog_rtl/1)
    ]
  end

  def all("aspect-ratio") do
    [
      one("default", "Default", "The official aspect ratio example.", &aspect_ratio_default/1),
      one(
        "square",
        "Square",
        "The official square aspect ratio example.",
        &aspect_ratio_square/1
      ),
      one(
        "portrait",
        "Portrait",
        "The official portrait aspect ratio example.",
        &aspect_ratio_portrait/1
      ),
      one("rtl", "RTL", "The official right-to-left aspect ratio example.", &aspect_ratio_rtl/1)
    ]
  end

  def all("attachment") do
    [
      one("default", "Default", "The official attachment example.", &attachment_default/1),
      one("image", "Image", "The official image attachment group.", &attachment_image/1),
      one("states", "States", "The official attachment states.", &attachment_states/1),
      one("sizes", "Sizes", "The official attachment sizes.", &attachment_sizes/1),
      one("group", "Group", "The official mixed attachment group.", &attachment_group_example/1),
      one(
        "trigger",
        "Trigger",
        "The official dialog trigger attachment.",
        &attachment_trigger_example/1
      )
    ]
  end

  def all("avatar") do
    [
      one("default", "Default", "Image, badge, and group states.", &avatar_default/1),
      one("basic", "Basic", "Image with fallback initials.", &avatar_basic/1),
      one("badge", "Badge", "Avatar with a status badge.", &avatar_badge_example/1),
      one("badge-icon", "Badge icon", "Avatar badge with an icon.", &avatar_badge_icon/1),
      one("group", "Group", "Three overlapping avatars.", &avatar_group_example/1),
      one(
        "group-count",
        "Group count",
        "Avatar group with a text count.",
        &avatar_group_count_example/1
      ),
      one(
        "group-count-icon",
        "Group count icon",
        "Avatar group with an icon count.",
        &avatar_group_count_icon/1
      ),
      one("size", "Size", "Small, default, and large avatars.", &avatar_size/1),
      one("dropdown", "Dropdown", "Avatar used as a menu trigger.", &avatar_dropdown/1),
      one("rtl", "Right to left", "Avatar states in an RTL container.", &avatar_rtl/1)
    ]
  end

  def all("bubble") do
    [
      one("default", "Default", "The official Bubble example.", &bubble_default/1),
      one("variants", "Variants", "All official Bubble variants.", &bubble_variants/1),
      one("alignment", "Alignment", "Start and end alignment.", &bubble_alignment/1),
      one("group-demo", "Group", "Grouped messages from one side.", &bubble_group_demo/1),
      one("link-button", "Link button", "Bubbles rendered as buttons.", &bubble_link_button/1),
      one(
        "reactions",
        "Reactions",
        "Reaction placement and actions.",
        &bubble_reactions_example/1
      ),
      one("collapsible", "Collapsible", "A long answer that can expand.", &bubble_collapsible/1),
      one("tooltip", "Tooltip", "A read receipt with a tooltip.", &bubble_tooltip/1),
      one("popover", "Popover", "Error details in a popover.", &bubble_popover/1)
    ]
  end

  def all("button-group") do
    [
      one("default", "Default", "The official button group example.", &button_group_default/1),
      one(
        "orientation",
        "Orientation",
        "The official vertical button group.",
        &button_group_orientation/1
      ),
      one("size", "Size", "The official button group sizes.", &button_group_size/1),
      one("nested", "Nested", "The official nested button groups.", &button_group_nested/1),
      one(
        "separator",
        "Separator",
        "The official separator example.",
        &button_group_separator_example/1
      ),
      one("split", "Split", "The official split button group.", &button_group_split/1),
      one("input", "Input", "The official input button group.", &button_group_input/1),
      one(
        "input-group",
        "Input group",
        "The official input group composition.",
        &button_group_input_group/1
      ),
      one("dropdown", "Dropdown", "The official dropdown composition.", &button_group_dropdown/1),
      one("select", "Select", "The official select composition.", &button_group_select/1),
      one("popover", "Popover", "The official popover composition.", &button_group_popover/1),
      one("rtl", "Right to left", "The official Arabic button group.", &button_group_rtl/1)
    ]
  end

  def all("item") do
    [
      one("default", "Default", "The pinned official Item example.", &item_default/1),
      one("variant", "Variant", "The pinned official Item variants.", &item_variant/1),
      one("size", "Size", "The pinned official Item sizes.", &item_size/1),
      one("icon", "Icon", "The pinned official icon Item.", &item_icon/1),
      one("avatar", "Avatar", "The pinned official avatar Items.", &item_avatar/1),
      one("image", "Image", "The pinned official image Items.", &item_image/1),
      one("group", "Group", "The pinned official Item group.", &item_group_example/1),
      one("header", "Header", "The pinned official Item headers.", &item_header_example/1),
      one("link", "Link", "The pinned official Item links.", &item_link/1),
      one("dropdown", "Dropdown", "The pinned official Item dropdown.", &item_dropdown/1),
      one("rtl", "Right to left", "The pinned official Arabic Item.", &item_rtl/1)
    ]
  end

  def all("marker") do
    [
      one("default", "Default", "The pinned official marker example.", &marker_default/1),
      one("variants", "Variants", "The pinned official marker variants.", &marker_variants/1),
      one("status", "Status", "The pinned official status markers.", &marker_status/1),
      one("shimmer", "Shimmer", "The pinned official shimmer markers.", &marker_shimmer/1),
      one(
        "separator",
        "Separator",
        "The pinned official separator markers.",
        &marker_separator/1
      ),
      one("border", "Border", "The pinned official border markers.", &marker_border/1),
      one("icon", "Icon", "The pinned official marker icon layouts.", &marker_icon_example/1),
      one(
        "link-button",
        "Link and button",
        "The pinned official link and button markers.",
        &marker_link_button/1
      )
    ]
  end

  # Named by its source as well as its name: AI Elements has a `message` too,
  # and an example named after the name alone would belong to neither. The
  # separator is a dash rather than a slash because this name is a URL segment
  # and a file name as well as a key.
  def all("shadcn-message") do
    [
      one("default", "Default", "The official message example.", &message_default/1),
      one(
        "avatar",
        "Avatar",
        "The official avatar message example.",
        &message_avatar_example/1
      ),
      one("group", "Group", "The official grouped message example.", &message_group_example/1),
      one(
        "header-footer",
        "Header and footer",
        "The official message header and footer example.",
        &message_header_footer/1
      ),
      one("actions", "Actions", "The official message actions example.", &message_actions/1),
      one(
        "attachment",
        "Attachment",
        "The official message attachment example.",
        &message_attachment/1
      )
    ]
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
      one("default", "Default", "The official delivery-time drawer example.", &drawer_default/1),
      one("sides", "Sides", "The official left-side drawer example.", &drawer_sides/1),
      one(
        "swipe-handle",
        "Swipe handle",
        "The official drawer with a visible swipe handle.",
        &drawer_swipe_handle/1
      ),
      one("nested", "Nested", "The official four-level drawer stack.", &drawer_nested/1),
      one(
        "non-modal",
        "Non-modal",
        "The official non-modal drawer example.",
        &drawer_non_modal/1
      ),
      one(
        "snap-points",
        "Snap points",
        "The official two-position drawer example.",
        &drawer_snap_points/1
      ),
      one(
        "dialog",
        "Responsive dialog",
        "The official dialog on desktop and drawer on small screens.",
        &drawer_dialog/1
      )
    ]
  end

  def all("menubar") do
    [
      one("default", "Default", "The official menubar example.", &menubar_default/1),
      one("checkbox", "Checkbox", "The official checkbox menu example.", &menubar_checkbox/1),
      one("radio", "Radio", "The official radio menu example.", &menubar_radio/1),
      one("submenu", "Submenu", "The official submenu example.", &menubar_submenu/1),
      one("icons", "Icons", "The official icon menu example.", &menubar_icons/1),
      one("rtl", "Right to left", "The official Arabic menubar example.", &menubar_rtl/1)
    ]
  end

  def all("input-group") do
    [
      one("default", "Default", "The official input group example.", &input_group_default/1),
      one(
        "inline-start",
        "Inline start",
        "The official leading icon example.",
        &input_group_inline_start/1
      ),
      one(
        "inline-end",
        "Inline end",
        "The official trailing icon example.",
        &input_group_inline_end/1
      ),
      one(
        "block-start",
        "Block start",
        "The official header addon example.",
        &input_group_block_start/1
      ),
      one(
        "block-end",
        "Block end",
        "The official footer addon example.",
        &input_group_block_end/1
      ),
      one("icon", "Icon", "The official icon addon examples.", &input_group_icon/1),
      one("text", "Text", "The official text addon examples.", &input_group_text_example/1),
      one(
        "button",
        "Button",
        "The official button addon examples.",
        &input_group_button_example/1
      ),
      one(
        "kbd",
        "Keyboard shortcut",
        "The official keyboard shortcut example.",
        &input_group_kbd/1
      ),
      one(
        "dropdown",
        "Dropdown",
        "The official dropdown trigger examples.",
        &input_group_dropdown/1
      ),
      one("spinner", "Spinner", "The official loading state examples.", &input_group_spinner/1),
      one(
        "textarea",
        "Textarea",
        "The official code textarea example.",
        &input_group_textarea_example/1
      ),
      one(
        "custom",
        "Custom",
        "The official auto-growing textarea example.",
        &input_group_custom/1
      ),
      one("rtl", "Right to left", "The official Arabic input group examples.", &input_group_rtl/1)
    ]
  end

  def all("input-otp") do
    [
      one("default", "Default", "The official six-digit example.", &input_otp_default/1),
      one("pattern", "Pattern", "The official digits-only example.", &input_otp_pattern/1),
      one(
        "separator",
        "Separator",
        "The official separated code example.",
        &input_otp_separator_example/1
      ),
      one("disabled", "Disabled", "The official disabled example.", &input_otp_disabled/1),
      one(
        "controlled",
        "Controlled",
        "The official controlled example.",
        &input_otp_controlled/1
      ),
      one("invalid", "Invalid", "The official invalid example.", &input_otp_invalid/1),
      one(
        "four-digits",
        "Four digits",
        "The official four-digit example.",
        &input_otp_four_digits/1
      ),
      one(
        "alphanumeric",
        "Alphanumeric",
        "The official alphanumeric example.",
        &input_otp_alphanumeric/1
      ),
      one("form", "Form", "The official verification form.", &input_otp_form/1),
      one("rtl", "Right to left", "The official Arabic example.", &input_otp_rtl/1)
    ]
  end

  def all("native-select") do
    [
      one(
        "default",
        "Default",
        "The official status example.",
        &native_select_default/1
      ),
      one("groups", "Groups", "The official grouped example.", &native_select_groups/1),
      one("disabled", "Disabled", "The official disabled example.", &native_select_disabled/1),
      one("invalid", "Invalid", "The official error example.", &native_select_invalid/1),
      one("rtl", "Right to left", "The official Arabic example.", &native_select_rtl/1)
    ]
  end

  def all("command") do
    [
      one("default", "Default", "The pinned official Command example.", &command_default/1),
      one("basic", "Basic", "The pinned official dialog example.", &command_basic/1),
      one(
        "shortcuts",
        "Shortcuts",
        "The pinned official shortcut example.",
        &command_shortcuts/1
      ),
      one("groups", "Groups", "The pinned official grouped example.", &command_groups/1),
      one(
        "scrollable",
        "Scrollable",
        "The pinned official long command list.",
        &command_scrollable/1
      ),
      one("rtl", "Right to left", "The pinned official Arabic example.", &command_rtl/1)
    ]
  end

  def all("scroll-area") do
    [
      one(
        "default",
        "Tags",
        "The official vertical scroll area example.",
        &scroll_area_default/1
      ),
      one(
        "horizontal-demo",
        "Horizontal",
        "The official horizontal artwork example.",
        &scroll_area_horizontal/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &scroll_area_rtl/1)
    ]
  end

  def all("message-scroller") do
    [
      one(
        "default",
        "Default",
        "The pinned official message scroller example.",
        &message_scroller_default/1
      ),
      one(
        "anchoring",
        "Anchoring",
        "The pinned official anchoring example.",
        &message_scroller_anchoring/1
      ),
      one(
        "group-chat",
        "Group chat",
        "The pinned official group chat example.",
        &message_scroller_group_chat/1
      ),
      one(
        "previous-context",
        "Previous context",
        "The pinned official previous context example.",
        &message_scroller_previous_context/1
      ),
      one(
        "streaming",
        "Streaming",
        "The pinned official streaming example.",
        &message_scroller_streaming/1
      ),
      one(
        "opening-position",
        "Opening position",
        "The pinned official opening position example.",
        &message_scroller_opening_position/1
      ),
      one(
        "load-history",
        "Load history",
        "The pinned official load history example.",
        &message_scroller_load_history/1
      ),
      one(
        "animation",
        "Animation",
        "The pinned official animation example.",
        &message_scroller_animation/1
      ),
      one(
        "commands",
        "Commands",
        "The pinned official commands example.",
        &message_scroller_commands/1
      ),
      one(
        "visibility",
        "Visibility",
        "The pinned official visibility example.",
        &message_scroller_visibility/1
      ),
      one(
        "scrollable",
        "Scrollable",
        "The pinned official scrollable example.",
        &message_scroller_scrollable/1
      )
    ]
  end

  def all("slider") do
    [
      one(
        "default",
        "Default",
        "The pinned official slider example.",
        &slider_default/1
      ),
      one(
        "range",
        "Range",
        "The pinned official range example.",
        &slider_range/1
      ),
      one("multiple", "Multiple", "The pinned official three-thumb example.", &slider_multiple/1),
      one("vertical", "Vertical", "The pinned official vertical example.", &slider_vertical/1),
      one(
        "controlled",
        "Controlled",
        "The pinned official controlled example.",
        &slider_controlled/1
      ),
      one("disabled", "Disabled", "The pinned official disabled example.", &slider_disabled/1),
      one("rtl", "Right to left", "The pinned official RTL example.", &slider_rtl/1)
    ]
  end

  def all("toast") do
    [
      one(
        "default",
        "Default",
        "The official event toast example.",
        &toast_default/1
      ),
      one("types", "Types", "The official toast type examples.", &toast_types/1),
      one("promise", "Promise", "The official Promise toast example.", &toast_promise/1)
    ]
  end

  def all("sonner") do
    [
      one(
        "basic",
        "Basic",
        "The pinned official basic Sonner example.",
        &sonner_basic/1
      ),
      one(
        "with-description",
        "With Description",
        "The pinned official Sonner example with a description.",
        &sonner_with_description/1
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
        "Default",
        "The pinned Question example with choices and freeform input.",
        &question_default/1
      ),
      one("freeform", "Freeform", "The pinned freeform Question example.", &question_freeform/1),
      one(
        "multi-select",
        "Multiple selection",
        "The pinned multiple-choice Question example.",
        &question_multi_select/1
      ),
      one(
        "single-select",
        "Single selection",
        "The pinned single-choice Question example.",
        &question_single_select/1
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
      ),
      one(
        "multiple",
        "Multiple",
        "The official multiple-choice example.",
        &questionnaire_multiple/1
      ),
      one("freeform", "Freeform", "The official freeform example.", &questionnaire_freeform/1),
      one("skip", "Skip", "The official skip example.", &questionnaire_skip_example/1),
      one("shortcuts", "Shortcuts", "The official shortcut example.", &questionnaire_shortcuts/1),
      one(
        "validation",
        "Validation",
        "The official validation example.",
        &questionnaire_validation/1
      ),
      one(
        "controlled",
        "Controlled",
        "The official controlled example.",
        &questionnaire_controlled/1
      ),
      one("resume", "Resume", "The official resume example.", &questionnaire_resume/1),
      one(
        "conditional",
        "Conditional",
        "The official conditional example.",
        &questionnaire_conditional/1
      ),
      one(
        "navigation-state",
        "Navigation state",
        "The official navigation state example.",
        &questionnaire_navigation_state/1
      ),
      one(
        "progress",
        "Progress",
        "The official progress example.",
        &questionnaire_progress_example/1
      ),
      one("animated", "Animated", "The official animated example.", &questionnaire_animated/1),
      one("card", "Card", "The official card example.", &questionnaire_card/1),
      one("dialog", "Dialog", "The official dialog example.", &questionnaire_dialog/1)
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
    [
      one("default", "Default", "The official Pagination example.", &pagination_default/1),
      one("simple", "Simple", "The official page-link example.", &pagination_simple/1),
      one(
        "icons-only",
        "Icons only",
        "The official compact pagination example.",
        &pagination_icons_only/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &pagination_rtl/1)
    ]
  end

  def all("badge") do
    [
      one("default", "Badge", "The official Badge example.", &badge_default/1),
      one("variants", "Variants", "Every official Badge variant.", &badge_variants/1),
      one("icon", "Icons", "Icons before and after the label.", &badge_icon/1),
      one("spinner", "Spinner", "Progress indicators inside badges.", &badge_spinner/1),
      one("link", "Link", "A badge rendered as a link.", &badge_link/1),
      one("colors", "Colors", "Custom color classes.", &badge_colors/1),
      one("rtl", "Right to left", "The official Arabic example.", &badge_rtl/1)
    ]
  end

  def all("breadcrumb") do
    [
      one("default", "Default", "The pinned official breadcrumb example.", &breadcrumb_default/1),
      one("basic", "Basic", "The pinned official basic example.", &breadcrumb_basic/1),
      one("link", "Link", "The pinned official link example.", &breadcrumb_link_example/1),
      one(
        "separator",
        "Custom separator",
        "The pinned official custom separator example.",
        &breadcrumb_separator_example/1
      ),
      one(
        "ellipsis",
        "Ellipsis",
        "The pinned official ellipsis example.",
        &breadcrumb_ellipsis_example/1
      ),
      one(
        "dropdown",
        "Dropdown",
        "The pinned official dropdown example.",
        &breadcrumb_dropdown/1
      ),
      one("rtl", "Right to left", "The pinned official RTL example.", &breadcrumb_rtl/1)
    ]
  end

  def all("button") do
    [
      one("default", "Default", "The official Button example.", &button_demo/1),
      one("size", "Size", "The official Button size example.", &button_size/1),
      one(
        "button-default",
        "Button default",
        "The official default variant example.",
        &button_default_example/1
      ),
      one("outline", "Outline", "The official outline variant example.", &button_outline/1),
      one(
        "secondary",
        "Secondary",
        "The official secondary variant example.",
        &button_secondary/1
      ),
      one("ghost", "Ghost", "The official ghost variant example.", &button_ghost/1),
      one(
        "destructive",
        "Destructive",
        "The official destructive variant example.",
        &button_destructive/1
      ),
      one("link", "Link", "The official link variant example.", &button_link_example/1),
      one("icon", "Icon", "The official icon button example.", &button_icon/1),
      one(
        "with-icon",
        "With icon",
        "The official buttons with icons example.",
        &button_with_icon/1
      ),
      one("rounded", "Rounded", "The official rounded Button example.", &button_rounded/1),
      one("spinner", "Spinner", "The official loading Button example.", &button_spinner/1),
      one(
        "group-demo",
        "Button group",
        "The official Button group example.",
        &button_group_demo_example/1
      ),
      one(
        "render",
        "Render",
        "The official anchor rendered with Button classes.",
        &button_render/1
      ),
      one("rtl", "Right to left", "The official Arabic Button example.", &button_rtl/1)
    ]
  end

  def all("checkbox") do
    [
      one("default", "Default", "The official Checkbox example.", &checkbox_default/1),
      one("basic", "Basic", "The official basic example.", &checkbox_basic/1),
      one(
        "description",
        "Description",
        "The official description example.",
        &checkbox_description/1
      ),
      one("disabled", "Disabled", "The official disabled example.", &checkbox_disabled/1),
      one("invalid", "Invalid", "The official invalid example.", &checkbox_invalid/1),
      one("group", "Group", "The official checkbox group.", &checkbox_group/1),
      one("table", "Table", "The official row selection example.", &checkbox_table/1),
      one("rtl", "Right to left", "The official Arabic example.", &checkbox_rtl/1)
    ]
  end

  def all("hover-card") do
    [
      one("default", "Default", "The official Hover Card example.", &hover_card_default/1),
      one("sides", "Sides", "The official side examples.", &hover_card_sides/1),
      one("rtl", "Right to left", "The official Arabic example.", &hover_card_rtl/1)
    ]
  end

  def all("input") do
    [
      one("default", "Default", "The official Input example.", &input_default/1),
      one("basic", "Basic", "The official basic input example.", &input_basic/1),
      one("field", "Field", "The official labelled input example.", &input_field/1),
      one(
        "fieldgroup",
        "Field group",
        "The official grouped input example.",
        &input_fieldgroup/1
      ),
      one("disabled", "Disabled", "The official disabled input example.", &input_disabled/1),
      one("invalid", "Invalid", "The official invalid input example.", &input_invalid/1),
      one("file", "File", "The official file input example.", &input_file/1),
      one("inline", "Inline", "The official inline input example.", &input_inline/1),
      one("grid", "Grid", "The official grid input example.", &input_grid/1),
      one("required", "Required", "The official required input example.", &input_required/1),
      one("badge", "Badge", "The official badge input example.", &input_badge/1),
      one(
        "input-group",
        "Input group",
        "The official input group example.",
        &input_input_group/1
      ),
      one(
        "button-group",
        "Button group",
        "The official button group example.",
        &input_button_group/1
      ),
      one("form", "Form", "The official input form example.", &input_form/1),
      one("rtl", "Right to left", "The official Arabic input example.", &input_rtl/1)
    ]
  end

  def all("label") do
    [
      one("default", "Default", "The official Label example.", &label_default/1),
      one(
        "field-demo",
        "Field demo",
        "The official checkout field example.",
        &label_field_demo/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &label_rtl/1)
    ]
  end

  def all("switch") do
    [
      one(
        "default",
        "Default",
        "The official airplane mode example.",
        &switch_default/1
      ),
      one(
        "description",
        "Description",
        "The official description example.",
        &switch_description/1
      ),
      one(
        "choice-card",
        "Choice card",
        "The official choice-card example.",
        &switch_choice_card/1
      ),
      one("disabled", "Disabled", "The official disabled example.", &switch_disabled/1),
      one("invalid", "Invalid", "The official error example.", &switch_invalid/1),
      one("sizes", "Sizes", "The official size examples.", &switch_sizes/1),
      one("rtl", "Right to left", "The official Arabic example.", &switch_rtl/1)
    ]
  end

  def all("tabs") do
    [
      one("default", "Default", "The official tabs example.", &tabs_default/1),
      one("line", "Line", "The official line variant.", &tabs_line/1),
      one("vertical", "Vertical", "The official vertical example.", &tabs_vertical/1),
      one("disabled", "Disabled", "The official disabled example.", &tabs_disabled/1),
      one("icons", "Icons", "The official icon example.", &tabs_icons/1),
      one("rtl", "Right to left", "The official Arabic example.", &tabs_rtl/1)
    ]
  end

  def all("textarea") do
    [
      one("default", "Default", "The official message example.", &textarea_default/1),
      one("field", "Field", "The official labelled example.", &textarea_field/1),
      one("disabled", "Disabled", "The official disabled example.", &textarea_disabled/1),
      one("invalid", "Invalid", "The official error example.", &textarea_invalid/1),
      one("button", "Button", "The official action example.", &textarea_button/1),
      one("rtl", "Right to left", "The official Arabic example.", &textarea_rtl/1)
    ]
  end

  def all("toggle") do
    [
      one("default", "Default", "The official bookmark example.", &toggle_default/1),
      one("outline", "Outline", "The official outlined examples.", &toggle_outline/1),
      one("text", "Text", "The official icon and text example.", &toggle_text/1),
      one("sizes", "Sizes", "The official size examples.", &toggle_sizes/1),
      one("disabled", "Disabled", "The official disabled examples.", &toggle_disabled/1),
      one("rtl", "Right to left", "The official Arabic example.", &toggle_rtl/1)
    ]
  end

  def all("toggle-group") do
    [
      one(
        "default",
        "Default",
        "The official multiple selection example.",
        &toggle_group_default/1
      ),
      one("outline", "Outline", "The official outline example.", &toggle_group_outline/1),
      one("sizes", "Sizes", "The official size examples.", &toggle_group_sizes/1),
      one("spacing", "Spacing", "The official spaced example.", &toggle_group_spacing/1),
      one("vertical", "Vertical", "The official vertical example.", &toggle_group_vertical/1),
      one("disabled", "Disabled", "The official disabled example.", &toggle_group_disabled/1),
      one(
        "font-weight-selector",
        "Font weight selector",
        "The official font weight selector.",
        &toggle_group_font_weight_selector/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &toggle_group_rtl/1)
    ]
  end

  def all("tooltip") do
    [
      one("default", "Default", "The official tooltip example.", &tooltip_default/1),
      one("sides", "Sides", "The official tooltip side examples.", &tooltip_sides/1),
      one("keyboard", "Keyboard", "The official keyboard tooltip example.", &tooltip_keyboard/1),
      one(
        "disabled",
        "Disabled",
        "The official disabled-control tooltip example.",
        &tooltip_disabled/1
      ),
      one("rtl", "Right to left", "The official RTL tooltip example.", &tooltip_rtl/1)
    ]
  end

  def all("card") do
    [
      one("default", "Default", "The pinned official card example.", &card_default/1),
      one("small", "Small", "The pinned official small card example.", &card_small/1),
      one("spacing", "Spacing", "The pinned official card spacing example.", &card_spacing/1),
      one(
        "edge-to-edge",
        "Edge to edge",
        "The pinned official edge-to-edge card example.",
        &card_edge_to_edge/1
      ),
      one("image", "Image", "The pinned official image card example.", &card_image/1),
      one("rtl", "Right to left", "The pinned official RTL card example.", &card_rtl/1)
    ]
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
        "Image grid",
        "The pinned attachment grid, with images and file icons.",
        &attachments_default/1
      ),
      one(
        "list",
        "List",
        "The pinned attachment list, with media types and remove actions.",
        &attachments_list/1
      ),
      one(
        "inline",
        "Inline",
        "The pinned inline attachments, with hover details and remove actions.",
        &attachments_inline/1
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
    [
      one("default", "Payment method", "The official payment form example.", &field_default/1),
      one("input", "Input", "The official input field example.", &field_input/1),
      one("textarea", "Textarea", "The official textarea field example.", &field_textarea/1),
      one("select", "Select", "The official select field example.", &field_select/1),
      one("slider", "Slider", "The official price range example.", &field_slider/1),
      one("fieldset", "Fieldset", "The official address fieldset example.", &field_fieldset/1),
      one("checkbox", "Checkbox", "The official checkbox field example.", &field_checkbox/1),
      one("radio", "Radio", "The official radio field example.", &field_radio/1),
      one("switch", "Switch", "The official switch field example.", &field_switch/1),
      one(
        "choice-card",
        "Choice card",
        "The official choice card field example.",
        &field_choice_card/1
      ),
      one("group", "Group", "The official grouped field example.", &field_group_example/1),
      one("rtl", "Right to left", "The official Arabic payment form.", &field_rtl/1),
      one(
        "responsive",
        "Responsive",
        "The official responsive field example.",
        &field_responsive/1
      )
    ]
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
        "Default",
        "The official file deletion approval request.",
        &confirmation_default/1
      ),
      one(
        "request",
        "Request",
        "The official production database approval request.",
        &confirmation_request_example/1
      ),
      one(
        "accepted",
        "Accepted",
        "The official approved tool result.",
        &confirmation_accepted_example/1
      ),
      one(
        "rejected",
        "Rejected",
        "The official rejected tool result.",
        &confirmation_rejected_example/1
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
      one("default", "Default", "The official order details example.", &collapsible_default/1),
      one("basic", "Basic", "The official basic card example.", &collapsible_basic/1),
      one(
        "settings",
        "Settings",
        "The official radius settings example.",
        &collapsible_settings/1
      ),
      one(
        "file-tree",
        "File tree",
        "The official nested file tree example.",
        &collapsible_file_tree/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &collapsible_rtl/1)
    ]
  end

  def all("combobox") do
    [
      one("default", "Default", "The official framework combobox.", &combobox_default/1),
      one("basic", "Basic", "The official basic framework combobox.", &combobox_basic/1),
      one(
        "multiple",
        "Multiple",
        "The official multiple framework combobox.",
        &combobox_multiple/1
      ),
      one(
        "clear",
        "Clear",
        "The official clearable framework combobox.",
        &combobox_clear_example/1
      ),
      one("groups", "Groups", "The official grouped timezone combobox.", &combobox_groups/1),
      one("custom", "Custom", "The official country item combobox.", &combobox_custom/1),
      one("invalid", "Invalid", "The official invalid framework combobox.", &combobox_invalid/1),
      one(
        "disabled",
        "Disabled",
        "The official disabled framework combobox.",
        &combobox_disabled/1
      ),
      one(
        "auto-highlight",
        "Auto highlight",
        "The official highlighted framework combobox.",
        &combobox_auto_highlight/1
      ),
      one("popup", "Popup", "The official trigger and popup combobox.", &combobox_popup/1),
      one(
        "input-group",
        "Input group",
        "The official timezone input-group combobox.",
        &combobox_input_group/1
      ),
      one("rtl", "Right to left", "The official Arabic multiple combobox.", &combobox_rtl/1)
    ]
  end

  def all("context-menu") do
    [
      one("default", "Default", "The official Context Menu example.", &context_menu_demo/1),
      one("basic", "Basic", "The official basic example.", &context_menu_basic/1),
      one("submenu", "Submenu", "The official submenu example.", &context_menu_submenu/1),
      one(
        "shortcuts",
        "Shortcuts",
        "The official keyboard shortcut example.",
        &context_menu_shortcuts/1
      ),
      one("groups", "Groups", "The official grouped example.", &context_menu_groups/1),
      one("icons", "Icons", "The official icon example.", &context_menu_icons/1),
      one(
        "checkboxes",
        "Checkboxes",
        "The official checkbox item example.",
        &context_menu_checkboxes/1
      ),
      one("radio", "Radio", "The official radio item example.", &context_menu_radio/1),
      one(
        "destructive",
        "Destructive",
        "The official destructive item example.",
        &context_menu_destructive/1
      ),
      one("sides", "Sides", "The official side examples.", &context_menu_sides/1),
      one("rtl", "Right to left", "The official Arabic example.", &context_menu_rtl/1)
    ]
  end

  def all("navigation-menu") do
    [
      one(
        "default",
        "Default",
        "The official navigation menu example.",
        &navigation_menu_default/1
      ),
      one(
        "rtl",
        "Right to left",
        "The official Arabic navigation menu example.",
        &navigation_menu_rtl/1
      )
    ]
  end

  def all("dialog") do
    [
      one("default", "Default", "The pinned official dialog example.", &dialog_default/1),
      one(
        "close-button",
        "Close button",
        "The pinned official footer close button example.",
        &dialog_close_button/1
      ),
      one(
        "no-close-button",
        "No close button",
        "The pinned official example without a top close button.",
        &dialog_no_close_button/1
      ),
      one(
        "sticky-footer",
        "Sticky footer",
        "The pinned official scrolling example with a footer.",
        &dialog_sticky_footer/1
      ),
      one(
        "scrollable-content",
        "Scrollable content",
        "The pinned official scrolling content example.",
        &dialog_scrollable_content/1
      ),
      one("rtl", "Right to left", "The pinned official Arabic example.", &dialog_rtl/1)
    ]
  end

  def all("dropdown-menu") do
    [
      one("default", "Default", "The pinned official menu example.", &dropdown_menu_default/1),
      one("basic", "Basic", "The pinned official basic menu.", &dropdown_menu_basic/1),
      one("submenu", "Submenu", "The pinned official nested menu.", &dropdown_menu_submenu/1),
      one(
        "shortcuts",
        "Shortcuts",
        "The pinned official shortcut menu.",
        &dropdown_menu_shortcuts/1
      ),
      one("icons", "Icons", "The pinned official icon menu.", &dropdown_menu_icons/1),
      one(
        "checkboxes",
        "Checkboxes",
        "The pinned official checkbox menu.",
        &dropdown_menu_checkboxes/1
      ),
      one(
        "checkboxes-icons",
        "Checkboxes with icons",
        "The pinned official notification menu.",
        &dropdown_menu_checkboxes_icons/1
      ),
      one(
        "radio-group",
        "Radio group",
        "The pinned official radio menu.",
        &dropdown_menu_radio_group/1
      ),
      one(
        "radio-icons",
        "Radio items with icons",
        "The pinned official payment menu.",
        &dropdown_menu_radio_icons/1
      ),
      one(
        "destructive",
        "Destructive",
        "The pinned official destructive menu item.",
        &dropdown_menu_destructive/1
      ),
      one("avatar", "Avatar", "The pinned official avatar trigger.", &dropdown_menu_avatar/1),
      one("complex", "Complex", "The pinned official complex menu.", &dropdown_menu_complex/1),
      one("rtl", "Right to left", "The pinned official Arabic menu.", &dropdown_menu_rtl/1)
    ]
  end

  def all("empty") do
    [
      one("default", "Default", "The official empty example.", &empty_default/1),
      one("outline", "Outline", "The official outlined empty example.", &empty_outline/1),
      one(
        "background",
        "Background",
        "The official empty example with a muted background.",
        &empty_background/1
      ),
      one("avatar", "Avatar", "The official avatar empty example.", &empty_avatar/1),
      one(
        "avatar-group",
        "Avatar group",
        "The official avatar group empty example.",
        &empty_avatar_group/1
      ),
      one(
        "input-group",
        "Input group",
        "The official input group empty example.",
        &empty_input_group/1
      ),
      one("rtl", "Right to left", "The official Arabic empty example.", &empty_rtl/1)
    ]
  end

  def all("kbd") do
    [
      one("default", "Default", "The pinned official keyboard example.", &kbd_default/1),
      one("group", "Group", "The pinned official keyboard group example.", &kbd_group_example/1),
      one("button", "Button", "The pinned official keyboard button example.", &kbd_button/1),
      one("tooltip", "Tooltip", "The pinned official keyboard tooltip example.", &kbd_tooltip/1),
      one(
        "input-group",
        "Input group",
        "The pinned official keyboard input group example.",
        &kbd_input_group/1
      ),
      one("rtl", "Right to left", "The pinned official RTL keyboard example.", &kbd_rtl/1)
    ]
  end

  def all("popover") do
    [
      one("default", "Default", "The official dimensions example.", &popover_default/1),
      one("basic", "Basic", "The official basic popover example.", &popover_basic/1),
      one(
        "alignments",
        "Alignments",
        "The official alignment examples.",
        &popover_alignments/1
      ),
      one("form", "Form", "The official form popover example.", &popover_form/1),
      one("rtl", "Right to left", "The official Arabic popover example.", &popover_rtl/1)
    ]
  end

  def all("progress") do
    [
      one("default", "Default", "The official progress example.", &progress_default/1),
      one("label", "Label", "The official labelled progress example.", &progress_label_example/1),
      one(
        "controlled",
        "Controlled",
        "The official slider-controlled progress example.",
        &progress_controlled/1
      ),
      one("rtl", "Right to left", "The official RTL progress example.", &progress_rtl/1)
    ]
  end

  def all("radio-group") do
    [
      one("default", "Default", "The official Radio Group example.", &radio_group_default/1),
      one(
        "description",
        "Description",
        "The official description example.",
        &radio_group_description/1
      ),
      one(
        "choice-card",
        "Choice card",
        "The official choice card example.",
        &radio_group_choice_card/1
      ),
      one("fieldset", "Fieldset", "The official fieldset example.", &radio_group_fieldset/1),
      one("disabled", "Disabled", "The official disabled example.", &radio_group_disabled/1),
      one("invalid", "Invalid", "The official invalid example.", &radio_group_invalid/1),
      one("rtl", "Right to left", "The official Arabic example.", &radio_group_rtl/1)
    ]
  end

  def all("resizable") do
    [
      one(
        "default",
        "Two panels",
        "Drag the separator to change their width.",
        &resizable_default/1
      ),
      one("vertical", "Vertical", "The official vertical panel example.", &resizable_vertical/1),
      one(
        "handle",
        "Handle",
        "The official visible handle example.",
        &resizable_handle_example/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &resizable_rtl/1)
    ]
  end

  def all("select") do
    [
      one("default", "Default", "The official Select example.", &select_default/1),
      one(
        "align-item",
        "Align item",
        "The official item-alignment example.",
        &select_align_item/1
      ),
      one("groups", "Groups", "The official grouped example.", &select_groups/1),
      one("scrollable", "Scrollable", "The official timezone example.", &select_scrollable/1),
      one("disabled", "Disabled", "The official disabled example.", &select_disabled/1),
      one("invalid", "Invalid", "The official error example.", &select_invalid/1),
      one("rtl", "Right to left", "The official Arabic example.", &select_rtl/1)
    ]
  end

  def all("separator") do
    [
      one("default", "Default", "The official separator example.", &separator_default/1),
      one(
        "vertical",
        "Vertical",
        "The official vertical separator example.",
        &separator_vertical/1
      ),
      one("menu", "Menu", "The official menu separator example.", &separator_menu/1),
      one("list", "List", "The official list separator example.", &separator_list/1),
      one("rtl", "RTL", "The official right-to-left separator example.", &separator_rtl/1)
    ]
  end

  def all("sheet") do
    [
      one("default", "Default", "The official profile sheet.", &sheet_default/1),
      one("side", "Sides", "The official four-side example.", &sheet_side/1),
      one(
        "no-close-button",
        "No close button",
        "The official sheet without a close button.",
        &sheet_no_close_button/1
      ),
      one("rtl", "Right to left", "The official Arabic example.", &sheet_rtl/1)
    ]
  end

  def all("skeleton") do
    [
      one("default", "Default", "The official skeleton example.", &skeleton_default/1),
      one("avatar", "Avatar", "The official avatar skeleton example.", &skeleton_avatar/1),
      one("card", "Card", "The official card skeleton example.", &skeleton_card/1),
      one("text", "Text", "The official text skeleton example.", &skeleton_text/1),
      one("form", "Form", "The official form skeleton example.", &skeleton_form/1),
      one("table", "Table", "The official table skeleton example.", &skeleton_table/1),
      one("rtl", "RTL", "The official right-to-left skeleton example.", &skeleton_rtl/1)
    ]
  end

  def all("spinner") do
    [
      one("default", "Default", "The official spinner example.", &spinner_default/1),
      one("custom", "Custom", "The official custom spinner example.", &spinner_custom/1),
      one("size", "Size", "The official spinner size example.", &spinner_size/1),
      one("button", "Button", "The official button spinner example.", &spinner_button/1),
      one("badge", "Badge", "The official badge spinner example.", &spinner_badge/1),
      one(
        "input-group",
        "Input group",
        "The official input group spinner example.",
        &spinner_input_group/1
      ),
      one("empty", "Empty", "The official empty spinner example.", &spinner_empty/1),
      one("rtl", "RTL", "The official right-to-left spinner example.", &spinner_rtl/1)
    ]
  end

  def all("table") do
    [
      one("default", "Default", "The official table example.", &table_default/1),
      one("footer", "Footer", "The official table footer example.", &table_footer_example/1),
      one("actions", "Actions", "The official table actions example.", &table_actions/1),
      one("rtl", "RTL", "The official right-to-left table example.", &table_rtl/1)
    ]
  end

  def all("data-table") do
    [
      one("default", "Default", "The pinned official Data Table example.", &data_table_default/1),
      one(
        "rtl",
        "Right to left",
        "The pinned official Arabic Data Table example.",
        &data_table_rtl/1
      )
    ]
  end

  def all("typography") do
    [
      one("default", "Default", "The pinned official Typography example.", &typography_demo/1),
      one("h1", "h1", "The pinned official h1 example.", &typography_h1/1),
      one("h2", "h2", "The pinned official h2 example.", &typography_h2/1),
      one("h3", "h3", "The pinned official h3 example.", &typography_h3/1),
      one("h4", "h4", "The pinned official h4 example.", &typography_h4/1),
      one("p", "p", "The pinned official paragraph example.", &typography_p/1),
      one(
        "blockquote",
        "Blockquote",
        "The pinned official blockquote example.",
        &typography_blockquote/1
      ),
      one("table", "Table", "The pinned official Typography table.", &typography_table/1),
      one("list", "List", "The pinned official list example.", &typography_list/1),
      one(
        "inline-code",
        "Inline code",
        "The pinned official inline code example.",
        &typography_inline_code/1
      ),
      one("lead", "Lead", "The pinned official lead example.", &typography_lead/1),
      one("large", "Large", "The pinned official large text example.", &typography_large/1),
      one("small", "Small", "The pinned official small text example.", &typography_small/1),
      one("muted", "Muted", "The pinned official muted text example.", &typography_muted/1),
      one(
        "rtl",
        "Right to left",
        "The pinned official Arabic Typography example.",
        &typography_rtl/1
      )
    ]
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
    <.accordion id="accordion-default" class="max-w-lg">
      <:item id="accordion-shipping" title="What are your shipping options?" open>
        We offer standard (5-7 days), express (2-3 days), and overnight shipping. Free shipping on international orders.
      </:item>
      <:item id="accordion-returns" title="What is your return policy?">
        Returns accepted within 30 days. Items must be unused and in original packaging. Refunds processed within 5-7 business days.
      </:item>
      <:item id="accordion-support" title="How can I contact customer support?">
        Reach us via email, live chat, or phone. We respond within 24 hours during business days.
      </:item>
    </.accordion>
    """
  end

  defp accordion_basic(assigns) do
    ~H"""
    <.accordion id="accordion-basic" class="max-w-lg">
      <:item id="accordion-basic-1" title="How do I reset my password?" open>
        Click on 'Forgot Password' on the login page, enter your email address, and we'll send you a link to reset your password. The link will expire in 24 hours.
      </:item>
      <:item id="accordion-basic-2" title="Can I change my subscription plan?">
        Yes, you can upgrade or downgrade your plan at any time from your account settings. Changes will be reflected in your next billing cycle.
      </:item>
      <:item id="accordion-basic-3" title="What payment methods do you accept?">
        We accept all major credit cards, PayPal, and bank transfers. All payments are processed securely through our payment partners.
      </:item>
    </.accordion>
    """
  end

  defp accordion_disabled(assigns) do
    ~H"""
    <.accordion id="accordion-disabled" class="w-full">
      <:item id="accordion-disabled-1" title="Can I access my account history?">
        Yes, you can view your complete account history including all transactions, plan changes, and support tickets in the Account History section of your dashboard.
      </:item>
      <:item id="accordion-disabled-2" title="Premium feature information" disabled>
        This section contains information about premium features. Upgrade your plan to access this content.
      </:item>
      <:item id="accordion-disabled-3" title="How do I update my email address?">
        You can update your email address in your account settings. You'll receive a verification email at your new address to confirm the change.
      </:item>
    </.accordion>
    """
  end

  defp accordion_multiple(assigns) do
    ~H"""
    <.accordion id="accordion-multiple" multiple class="max-w-lg">
      <:item id="accordion-notifications" title="Notification Settings" open>
        Manage how you receive notifications. You can enable email alerts for updates or push notifications for mobile devices.
      </:item>
      <:item id="accordion-privacy" title="Privacy & Security">
        Control your privacy settings and security preferences. Enable two-factor authentication, manage connected devices, review active sessions, and configure data sharing preferences. You can also download your data or delete your account.
      </:item>
      <:item id="accordion-multiple-billing" title="Billing & Subscription">
        View your current plan, payment history, and upcoming invoices. Update your payment method, change your subscription tier, or cancel your subscription.
      </:item>
    </.accordion>
    """
  end

  defp accordion_borders(assigns) do
    ~H"""
    <.accordion id="accordion-borders" class="max-w-lg rounded-lg border">
      <:item
        id="accordion-billing"
        title="How does billing work?"
        open
        class="border-b px-4 last:border-b-0"
      >
        We offer monthly and annual subscription plans. Billing is charged at the beginning of each cycle, and you can cancel anytime. All plans include automatic backups, 24/7 support, and unlimited team members.
      </:item>
      <:item id="accordion-security" title="Is my data secure?" class="border-b px-4 last:border-b-0">
        Yes. We use end-to-end encryption, SOC 2 Type II compliance, and regular third-party security audits. All data is encrypted at rest and in transit using industry-standard protocols.
      </:item>
      <:item
        id="accordion-integration"
        title="What integrations do you support?"
        class="border-b px-4 last:border-b-0"
      >
        We integrate with 500+ popular tools including Slack, Zapier, Salesforce, HubSpot, and more. You can also build custom integrations using our REST API and webhooks.
      </:item>
    </.accordion>
    """
  end

  defp accordion_card(assigns) do
    ~H"""
    <.card class="w-full max-w-sm">
      <.card_header>
        <.card_title>Subscription &amp; Billing</.card_title>
        <.card_description>
          Common questions about your account, plans, payments and cancellations.
        </.card_description>
      </.card_header>
      <.card_content>
        <.accordion id="accordion-card">
          <:item id="accordion-plans" title="What subscription plans do you offer?" open>
            We offer three subscription tiers: Starter ($9/month), Professional ($29/month), and Enterprise ($99/month). Each plan includes increasing storage limits, API access, priority support, and team collaboration features.
          </:item>
          <:item id="accordion-card-billing" title="How does billing work?">
            Billing occurs automatically at the start of each billing cycle. We accept all major credit cards, PayPal, and ACH transfers for enterprise customers. You'll receive an invoice via email after each payment.
          </:item>
          <:item id="accordion-cancel" title="How do I cancel my subscription?">
            You can cancel your subscription anytime from your account settings. There are no cancellation fees or penalties. Your access will continue until the end of your current billing period.
          </:item>
        </.accordion>
      </.card_content>
    </.card>
    """
  end

  defp accordion_rtl(assigns) do
    ~H"""
    <.accordion id="accordion-rtl" class="max-w-md">
      <:item
        id="accordion-rtl-1"
        title="كيف يمكنني إعادة تعيين كلمة المرور؟"
        open
      >
        انقر على 'نسيت كلمة المرور' في صفحة تسجيل الدخول، أدخل عنوان بريدك الإلكتروني، وسنرسل لك رابطًا لإعادة تعيين كلمة المرور. سينتهي صلاحية الرابط خلال 24 ساعة.
      </:item>
      <:item
        id="accordion-rtl-2"
        title="هل يمكنني تغيير خطة الاشتراك الخاصة بي؟"
      >
        نعم، يمكنك ترقية أو تخفيض خطتك في أي وقت من إعدادات حسابك. ستظهر التغييرات في دورة الفوترة التالية.
      </:item>
      <:item id="accordion-rtl-3" title="ما هي طرق الدفع التي تقبلونها؟">
        نقبل جميع بطاقات الائتمان الرئيسية و PayPal والتحويلات المصرفية. تتم معالجة جميع المدفوعات بأمان من خلال شركاء الدفع لدينا.
      </:item>
    </.accordion>
    """
  end

  defp alert_dialog_default(assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-default" trigger_variant="outline">
      <:trigger>Show Dialog</:trigger>
      <:title>Are you absolutely sure?</:title>
      <:description>
        This action cannot be undone. This will permanently delete your account from our servers.
      </:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-default">Cancel</.alert_dialog_cancel>
        <.alert_dialog_action>Continue</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_basic(assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-basic" trigger_variant="outline">
      <:trigger>Show Dialog</:trigger>
      <:title>Are you absolutely sure?</:title>
      <:description>
        This action cannot be undone. This will permanently delete your account and remove your data from our servers.
      </:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-basic">Cancel</.alert_dialog_cancel>
        <.alert_dialog_action>Continue</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_small(assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-small" trigger_variant="outline" size="sm">
      <:trigger>Show Dialog</:trigger>
      <:title>Allow accessory to connect?</:title>
      <:description>Do you want to allow the USB accessory to connect to this device?</:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-small">Don't allow</.alert_dialog_cancel>
        <.alert_dialog_action>Allow</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_media(assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-media" trigger_variant="outline">
      <:trigger>Share Project</:trigger>
      <:media><LiveShadcn.Icon.icon name="circle-fading-plus" /></:media>
      <:title>Share this project?</:title>
      <:description>Anyone with the link will be able to view and edit this project.</:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-media">Cancel</.alert_dialog_cancel>
        <.alert_dialog_action>Share</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_small_media(assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-small-media" trigger_variant="outline" size="sm">
      <:trigger>Show Dialog</:trigger>
      <:media><LiveShadcn.Icon.icon name="bluetooth" /></:media>
      <:title>Allow accessory to connect?</:title>
      <:description>Do you want to allow the USB accessory to connect to this device?</:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-small-media">Don't allow</.alert_dialog_cancel>
        <.alert_dialog_action>Allow</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_destructive(assigns) do
    ~H"""
    <.alert_dialog
      id="alert-dialog-destructive"
      trigger_variant="destructive"
      size="sm"
    >
      <:trigger>Delete Chat</:trigger>
      <:media class="bg-destructive/10 text-destructive dark:bg-destructive/20 dark:text-destructive">
        <LiveShadcn.Icon.icon name="trash-2" />
      </:media>
      <:title>Delete chat?</:title>
      <:description>
        This will permanently delete this chat conversation. View <a href="#">Settings</a>
        delete any memories saved during this chat.
      </:description>
      <:footer>
        <.alert_dialog_cancel for="alert-dialog-destructive">Cancel</.alert_dialog_cancel>
        <.alert_dialog_action variant="destructive">Delete</.alert_dialog_action>
      </:footer>
    </.alert_dialog>
    """
  end

  defp alert_dialog_rtl(assigns) do
    ~H"""
    <div class="flex gap-4" dir="rtl">
      <.alert_dialog
        id="alert-dialog-rtl-default"
        trigger_variant="outline"
        dir="rtl"
        data-lang="ar"
      >
        <:trigger>إظهار الحوار</:trigger>
        <:title>هل أنت متأكد تمامًا؟</:title>
        <:description>
          لا يمكن التراجع عن هذا الإجراء. سيؤدي هذا إلى حذف حسابك نهائيًا من خوادمنا.
        </:description>
        <:footer>
          <.alert_dialog_cancel for="alert-dialog-rtl-default">إلغاء</.alert_dialog_cancel>
          <.alert_dialog_action>متابعة</.alert_dialog_action>
        </:footer>
      </.alert_dialog>
      <.alert_dialog
        id="alert-dialog-rtl-small"
        trigger_variant="outline"
        size="sm"
        dir="rtl"
        data-lang="ar"
      >
        <:trigger>إظهار الحوار (صغير)</:trigger>
        <:media><LiveShadcn.Icon.icon name="bluetooth" /></:media>
        <:title>السماح للملحق بالاتصال؟</:title>
        <:description>هل تريد السماح لملحق USB بالاتصال بهذا الجهاز؟</:description>
        <:footer>
          <.alert_dialog_cancel for="alert-dialog-rtl-small">عدم السماح</.alert_dialog_cancel>
          <.alert_dialog_action>السماح</.alert_dialog_action>
        </:footer>
      </.alert_dialog>
    </div>
    """
  end

  defp sheet_default(assigns) do
    ~H"""
    <.sheet id="sheet-demo">
      <:trigger>Open</:trigger>
      <:title>Edit profile</:title>
      <:description>Make changes to your profile here. Click save when you're done.</:description>
      <:footer>
        <.button type="submit">Save changes</.button>
        <.button
          data-slot="sheet-close"
          variant="outline"
          phx-click={LiveBase.Dialog.close("sheet-demo")}
        >
          Close
        </.button>
      </:footer>
      <div class="grid flex-1 auto-rows-min gap-6 px-4">
        <div class="grid gap-3">
          <.label for="sheet-demo-name">Name</.label>
          <.input id="sheet-demo-name" value="Pedro Duarte" />
        </div>
        <div class="grid gap-3">
          <.label for="sheet-demo-username">Username</.label>
          <.input id="sheet-demo-username" value="@peduarte" />
        </div>
      </div>
    </.sheet>
    """
  end

  defp sheet_side(assigns) do
    assigns = assign(assigns, :sides, ["top", "right", "bottom", "left"])

    ~H"""
    <div class="flex flex-wrap gap-2">
      <.sheet
        :for={side <- @sides}
        id={"sheet-side-#{side}"}
        side={side}
        trigger_class="capitalize"
        class="data-[side=bottom]:max-h-[50vh] data-[side=top]:max-h-[50vh]"
      >
        <:trigger>{side}</:trigger>
        <:title>Edit profile</:title>
        <:description>
          Make changes to your profile here. Click save when you're done.
        </:description>
        <:footer>
          <.button type="submit">Save changes</.button>
          <.button
            data-slot="sheet-close"
            variant="outline"
            phx-click={LiveBase.Dialog.close("sheet-side-#{side}")}
          >
            Cancel
          </.button>
        </:footer>
        <div class="no-scrollbar overflow-y-auto px-4">
          <p :for={_index <- 1..10} class="mb-2 leading-relaxed">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
          </p>
        </div>
      </.sheet>
    </div>
    """
  end

  defp sheet_no_close_button(assigns) do
    ~H"""
    <.sheet id="sheet-no-close" show_close_button={false}>
      <:trigger>Open Sheet</:trigger>
      <:title>No Close Button</:title>
      <:description>
        This sheet doesn't have a close button in the top-right corner. Click outside to close.
      </:description>
    </.sheet>
    """
  end

  defp sheet_rtl(assigns) do
    ~H"""
    <.sheet id="sheet-rtl" side="left" dir="rtl" data-lang="ar">
      <:trigger>فتح</:trigger>
      <:title>تعديل الملف الشخصي</:title>
      <:description>
        قم بإجراء تغييرات على ملفك الشخصي هنا. انقر حفظ عند الانتهاء.
      </:description>
      <:footer>
        <.button type="submit">حفظ التغييرات</.button>
        <.button
          data-slot="sheet-close"
          variant="outline"
          phx-click={LiveBase.Dialog.close("sheet-rtl")}
        >
          إغلاق
        </.button>
      </:footer>
      <.field_group class="px-4">
        <.field>
          <.field_label for="sheet-rtl-name">الاسم</.field_label>
          <.input id="sheet-rtl-name" value="Pedro Duarte" />
        </.field>
        <.field>
          <.field_label for="sheet-rtl-username">اسم المستخدم</.field_label>
          <.input id="sheet-rtl-username" value="peduarte" />
        </.field>
      </.field_group>
    </.sheet>
    """
  end

  defp aspect_ratio_default(assigns) do
    ~H"""
    <.aspect_ratio ratio="1.7777777777777777" class="w-full max-w-sm rounded-lg bg-muted">
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Photo"
        class="rounded-lg object-cover grayscale dark:brightness-20"
        style="position: absolute; height: 100%; width: 100%; left: 0; top: 0; right: 0; bottom: 0; color: transparent;"
      />
    </.aspect_ratio>
    """
  end

  defp aspect_ratio_square(assigns) do
    ~H"""
    <.aspect_ratio ratio="1" class="w-full max-w-[12rem] rounded-lg bg-muted">
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Photo"
        class="rounded-lg object-cover grayscale dark:brightness-20"
        style="position: absolute; height: 100%; width: 100%; left: 0; top: 0; right: 0; bottom: 0; color: transparent;"
      />
    </.aspect_ratio>
    """
  end

  defp aspect_ratio_portrait(assigns) do
    ~H"""
    <.aspect_ratio ratio="0.5625" class="w-full max-w-[10rem] rounded-lg bg-muted">
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Photo"
        class="rounded-lg object-cover grayscale dark:brightness-20"
        style="position: absolute; height: 100%; width: 100%; left: 0; top: 0; right: 0; bottom: 0; color: transparent;"
      />
    </.aspect_ratio>
    """
  end

  defp aspect_ratio_rtl(assigns) do
    ~H"""
    <figure class="w-full max-w-sm" dir="rtl">
      <.aspect_ratio ratio="1.7777777777777777" class="rounded-lg bg-muted">
        <img
          src="https://avatar.vercel.sh/shadcn1"
          alt="Photo"
          class="rounded-lg object-cover grayscale dark:brightness-20"
          style="position: absolute; height: 100%; width: 100%; left: 0; top: 0; right: 0; bottom: 0; color: transparent;"
        />
      </.aspect_ratio>
      <figcaption class="mt-2 text-center text-sm text-muted-foreground">منظر طبيعي جميل</figcaption>
    </figure>
    """
  end

  defp attachment_default(assigns) do
    assigns = assign(assigns, :images, @attachment_images)

    ~H"""
    <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
      <.attachment_group>
        <.attachment :for={image <- @images} orientation="vertical">
          <.attachment_media variant="image">
            <img src={image.src} alt={image.alt} />
          </.attachment_media>
          <.attachment_content>
            <.attachment_title>{image.name}</.attachment_title>
            <.attachment_description>{image.meta}</.attachment_description>
          </.attachment_content>
        </.attachment>
      </.attachment_group>
      <.attachment state="uploading" class="w-full">
        <.attachment_media><.spinner /></.attachment_media>
        <.attachment_content>
          <.attachment_title>sales-dashboard.pdf</.attachment_title>
          <.attachment_description>Uploading · 64%</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Cancel upload">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
      <.attachment class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-code" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>message-renderer.tsx</.attachment_title>
          <.attachment_description>TypeScript · 12 KB</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Remove message-renderer.tsx">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
    </div>
    """
  end

  defp attachment_image(assigns) do
    assigns = assign(assigns, :images, @attachment_images)

    ~H"""
    <div class="mx-auto w-full max-w-sm py-12">
      <.attachment_group class="w-full">
        <.attachment :for={image <- @images} orientation="vertical">
          <.attachment_media variant="image">
            <img src={image.src} alt={image.alt} />
          </.attachment_media>
          <.attachment_content>
            <.attachment_title>{image.name}</.attachment_title>
            <.attachment_description>{image.meta}</.attachment_description>
          </.attachment_content>
          <.attachment_actions>
            <.attachment_action aria-label={"Remove #{image.name}"}>
              <LiveShadcn.Icon.icon name="x" />
            </.attachment_action>
          </.attachment_actions>
          <.attachment_trigger
            href={image.src}
            target="_blank"
            rel="noreferrer"
            aria-label={"Open #{image.name}"}
          />
        </.attachment>
      </.attachment_group>
    </div>
    """
  end

  defp attachment_states(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-sm flex-col gap-2 py-12">
      <.attachment state="idle" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="clock" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>selected-file.pdf</.attachment_title>
          <.attachment_description>Ready to upload</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Remove selected-file.pdf">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
      <.attachment state="uploading" class="w-full">
        <.attachment_media><.spinner /></.attachment_media>
        <.attachment_content>
          <.attachment_title>design-system.zip</.attachment_title>
          <.attachment_description>Uploading · 64%</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Cancel upload">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
      <.attachment state="processing" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>market-research.pdf</.attachment_title>
          <.attachment_description>Processing document</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Remove market-research.pdf">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
      <.attachment state="error" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-warning" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>financial-model.xlsx</.attachment_title>
          <.attachment_description>Upload failed. Try again.</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Retry upload">
            <LiveShadcn.Icon.icon name="refresh-cw" />
          </.attachment_action>
          <.attachment_action aria-label="Remove financial-model.xlsx">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
      <.attachment state="done" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="check" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>uploaded-report.pdf</.attachment_title>
          <.attachment_description>Uploaded · 1.8 MB</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Remove uploaded-report.pdf">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
      </.attachment>
    </div>
    """
  end

  defp attachment_sizes(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-sm flex-col gap-3 py-12">
      <.attachment size="default" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>Default attachment</.attachment_title>
          <.attachment_description>PDF · 2.4 MB</.attachment_description>
        </.attachment_content>
      </.attachment>
      <.attachment size="sm" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>Small attachment</.attachment_title>
          <.attachment_description>PDF · 2.4 MB</.attachment_description>
        </.attachment_content>
      </.attachment>
      <.attachment size="xs" class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-text" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>Extra small attachment</.attachment_title>
        </.attachment_content>
      </.attachment>
    </div>
    """
  end

  defp attachment_group_example(assigns) do
    assigns = assign(assigns, :items, @attachment_group_items)

    ~H"""
    <div class="mx-auto w-full max-w-sm py-12">
      <.attachment_group class="w-full">
        <.attachment :for={item <- @items} class="w-64">
          <.attachment_media :if={item[:src]} variant="image">
            <img src={item.src} alt={item.name} />
          </.attachment_media>
          <.attachment_media :if={item[:icon]}>
            <LiveShadcn.Icon.icon name={item.icon} />
          </.attachment_media>
          <.attachment_content>
            <.attachment_title>{item.name}</.attachment_title>
            <.attachment_description>{item.meta}</.attachment_description>
          </.attachment_content>
          <.attachment_actions>
            <.attachment_action aria-label={"Remove #{item.name}"}>
              <LiveShadcn.Icon.icon name="x" />
            </.attachment_action>
          </.attachment_actions>
        </.attachment>
      </.attachment_group>
    </div>
    """
  end

  defp attachment_trigger_example(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-sm py-12">
      <.attachment class="w-full">
        <.attachment_media><LiveShadcn.Icon.icon name="file-search" /></.attachment_media>
        <.attachment_content>
          <.attachment_title>research-summary.pdf</.attachment_title>
          <.attachment_description>Open preview dialog</.attachment_description>
        </.attachment_content>
        <.attachment_actions>
          <.attachment_action aria-label="Copy link">
            <LiveShadcn.Icon.icon name="copy" />
          </.attachment_action>
          <.attachment_action aria-label="Remove research-summary.pdf">
            <LiveShadcn.Icon.icon name="x" />
          </.attachment_action>
        </.attachment_actions>
        <.attachment_trigger
          data-slot="dialog-trigger"
          id={LiveBase.Dialog.trigger_id("attachment-trigger-dialog")}
          aria-label="Preview research-summary.pdf"
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={LiveBase.Dialog.popup_id("attachment-trigger-dialog")}
          phx-click={LiveBase.Dialog.open("attachment-trigger-dialog")}
          phx-mounted={LiveBase.Dialog.owned_attributes(:trigger)}
        />
      </.attachment>
      <.dialog id="attachment-trigger-dialog" show_trigger={false} class="sm:max-w-md">
        <:title>research-summary.pdf</:title>
        <:description>
          The attachment trigger fills the card and opens the dialog, while the actions stay independently clickable above it.
        </:description>
      </.dialog>
    </div>
    """
  end

  defp avatar_default(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap items-center gap-6 md:gap-12">
      <.avatar>
        <.avatar_image
          src="https://github.com/shadcn.png"
          alt="@shadcn"
          class="grayscale"
        />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
        <.avatar_badge class="bg-green-600 dark:bg-green-800" />
      </.avatar>
      <.avatar_group class="grayscale">
        <.avatar>
          <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
          <.avatar_fallback>CN</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
          <.avatar_fallback>LR</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
          <.avatar_fallback>ER</.avatar_fallback>
        </.avatar>
        <.avatar_group_count>+3</.avatar_group_count>
      </.avatar_group>
    </div>
    """
  end

  defp avatar_basic(assigns) do
    ~H"""
    <.avatar>
      <.avatar_image
        src="https://github.com/shadcn.png"
        alt="@shadcn"
        class="grayscale"
      />
      <.avatar_fallback>CN</.avatar_fallback>
    </.avatar>
    """
  end

  defp avatar_badge_example(assigns) do
    ~H"""
    <.avatar>
      <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
      <.avatar_fallback>CN</.avatar_fallback>
      <.avatar_badge class="bg-green-600 dark:bg-green-800" />
    </.avatar>
    """
  end

  defp avatar_badge_icon(assigns) do
    ~H"""
    <.avatar class="grayscale">
      <.avatar_image src="https://github.com/pranathip.png" alt="@pranathip" />
      <.avatar_fallback>PP</.avatar_fallback>
      <.avatar_badge><LiveShadcn.Icon.icon name="plus" /></.avatar_badge>
    </.avatar>
    """
  end

  defp avatar_group_example(assigns) do
    ~H"""
    <.avatar_group class="grayscale">
      <.avatar>
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
        <.avatar_fallback>LR</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
      </.avatar>
    </.avatar_group>
    """
  end

  defp avatar_group_count_example(assigns) do
    ~H"""
    <.avatar_group class="grayscale">
      <.avatar>
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
        <.avatar_fallback>LR</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
      </.avatar>
      <.avatar_group_count>+3</.avatar_group_count>
    </.avatar_group>
    """
  end

  defp avatar_group_count_icon(assigns) do
    ~H"""
    <.avatar_group class="grayscale">
      <.avatar>
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
        <.avatar_fallback>LR</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
      </.avatar>
      <.avatar_group_count><LiveShadcn.Icon.icon name="plus" /></.avatar_group_count>
    </.avatar_group>
    """
  end

  defp avatar_size(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2 grayscale">
      <.avatar size="sm">
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar size="lg">
        <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
    </div>
    """
  end

  defp avatar_dropdown(assigns) do
    ~H"""
    <.dropdown_menu
      id="avatar-dropdown"
      trigger_variant="ghost"
      trigger_size="icon"
      trigger_class="rounded-full"
      class="w-32"
      grouped
    >
      <:trigger>
        <.avatar>
          <.avatar_image src="https://github.com/shadcn.png" alt="shadcn" />
          <.avatar_fallback>CN</.avatar_fallback>
        </.avatar>
      </:trigger>
      <:entry kind="item" value="profile">Profile</:entry>
      <:entry kind="item" value="billing">Billing</:entry>
      <:entry kind="item" value="settings">Settings</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" variant="destructive">Log out</:entry>
    </.dropdown_menu>
    """
  end

  defp avatar_rtl(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap items-center gap-6 md:gap-12" dir="rtl">
      <.avatar>
        <.avatar_image
          src="https://github.com/shadcn.png"
          alt="@shadcn"
          class="grayscale"
        />
        <.avatar_fallback>CN</.avatar_fallback>
      </.avatar>
      <.avatar>
        <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
        <.avatar_badge class="bg-green-600 dark:bg-green-800" />
      </.avatar>
      <.avatar_group class="grayscale">
        <.avatar>
          <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
          <.avatar_fallback>CN</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
          <.avatar_fallback>LR</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
          <.avatar_fallback>ER</.avatar_fallback>
        </.avatar>
        <.avatar_group_count>+٣</.avatar_group_count>
      </.avatar_group>
    </div>
    """
  end

  defp bubble_default(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.bubble align="end">
        <.bubble_content>Hey there! what's up?</.bubble_content>
      </.bubble>
      <.bubble_group>
        <.bubble variant="muted">
          <.bubble_content>Hey! Want to see chat bubbles?</.bubble_content>
        </.bubble>
        <.bubble variant="muted">
          <.bubble_content>
            I can group messages, switch sides, and keep the whole thread easy to scan.
          </.bubble_content>
          <.bubble_reactions role="img" aria-label="Reaction: thumbs up">
            <span>👍</span>
          </.bubble_reactions>
        </.bubble>
      </.bubble_group>
      <.bubble align="end">
        <.bubble_content>Sure. Hit me with your best demo.</.bubble_content>
      </.bubble>
      <.bubble variant="muted">
        <.bubble_content>
          Yes. You are reading a demo that is demoing itself. Very meta. Very on-brand.
        </.bubble_content>
        <.bubble_reactions
          role="img"
          aria-label="Reactions: thumbs up, fire, eyes, and 2 more"
        >
          <span>👍</span>
          <span>🔥</span>
          <span>👀</span>
          <span>+2</span>
        </.bubble_reactions>
      </.bubble>
    </div>
    """
  end

  defp bubble_variants(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-12 py-12">
      <.bubble>
        <.bubble_content>This is the default primary bubble.</.bubble_content>
      </.bubble>
      <.bubble variant="secondary" align="end">
        <.bubble_content>This is the secondary variant.</.bubble_content>
      </.bubble>
      <.bubble variant="muted">
        <.bubble_content>
          This one is muted. It uses a lower emphasis color for the chat bubble.
        </.bubble_content>
        <.bubble_reactions role="img" aria-label="Reaction: thumbs up">
          <span>👍</span>
        </.bubble_reactions>
      </.bubble>
      <.bubble variant="tinted" align="end">
        <.bubble_content>
          This one is tinted. The tint is a softer color derived from the primary color.
        </.bubble_content>
      </.bubble>
      <.bubble variant="outline">
        <.bubble_content>We can also use an outlined variant.</.bubble_content>
      </.bubble>
      <.bubble variant="destructive" align="end">
        <.bubble_content>Or a destructive variant with a reaction.</.bubble_content>
        <.bubble_reactions role="img" aria-label="Reaction: fire">
          <span>🔥</span>
        </.bubble_reactions>
      </.bubble>
      <.bubble variant="ghost">
        <.bubble_content>
          Ghost bubbles work for assistant text, **markdown**, and other content that should not be framed.

          This is perfect for assistant messages that should not have a frame and can take the full width of the container. You can also render `code` in it.

          Ghost bubbles are full width and can take the full width of the container.
        </.bubble_content>
      </.bubble>
    </div>
    """
  end

  defp bubble_alignment(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.bubble variant="muted">
        <.bubble_content>
          This bubble is aligned to the start. This is the default alignment.
        </.bubble_content>
      </.bubble>
      <.bubble align="end">
        <.bubble_content>
          This bubble is aligned to the end. Use this for user messages.
        </.bubble_content>
      </.bubble>
    </div>
    """
  end

  defp bubble_group_demo(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.bubble variant="muted">
        <.bubble_content>Can you tell me what's the issue?</.bubble_content>
      </.bubble>
      <.bubble_group>
        <.bubble align="end">
          <.bubble_content>You tell me!</.bubble_content>
        </.bubble>
        <.bubble align="end">
          <.bubble_content>It worked yesterday. You broke it!</.bubble_content>
        </.bubble>
        <.bubble align="end">
          <.bubble_content>Find the bug and fix it.</.bubble_content>
          <.bubble_reactions aria-label="Reactions: eyes" align="start">
            <span>👀</span>
          </.bubble_reactions>
        </.bubble>
      </.bubble_group>
      <.bubble variant="muted">
        <.bubble_content>
          Want me to diff yesterday's you against today's you? It's a bit embarrassing.
        </.bubble_content>
      </.bubble>
    </div>
    """
  end

  defp bubble_link_button(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.bubble variant="muted">
        <.bubble_content>How can I help you today?</.bubble_content>
      </.bubble>
      <.bubble_group>
        <.bubble variant="tinted" align="end">
          <.bubble_content
            as="button"
            phx-click="bubble_toast"
            phx-value-message="forgot-password"
          >
            I forgot my password
          </.bubble_content>
        </.bubble>
        <.bubble variant="tinted" align="end">
          <.bubble_content
            as="button"
            phx-click="bubble_toast"
            phx-value-message="subscription"
          >
            I need help with my subscription
          </.bubble_content>
        </.bubble>
        <.bubble variant="tinted" align="end">
          <.bubble_content as="button" phx-click="bubble_toast" phx-value-message="human">
            Something else. Talk to a human.
          </.bubble_content>
        </.bubble>
      </.bubble_group>
    </div>
    """
  end

  defp bubble_reactions_example(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-12 py-12">
      <.bubble variant="muted" align="end">
        <.bubble_content>I don't need tests, I know my code works.</.bubble_content>
        <.bubble_reactions
          align="start"
          role="img"
          aria-label="Reactions: thumbs up, surprised"
        >
          <span>👍</span>
          <span>😮</span>
        </.bubble_reactions>
      </.bubble>
      <.bubble variant="muted">
        <.bubble_content>
          Bold. Fine I'll add some tests. I'll let you know when they're done.
        </.bubble_content>
        <.bubble_reactions role="img" aria-label="Reactions: eyes, rocket, and 2 more">
          <span>👀</span>
          <span>🚀</span>
          <span>+2</span>
        </.bubble_reactions>
      </.bubble>
      <.bubble variant="default" align="end">
        <.bubble_content>
          Tests passed on the first try. All 142 of them. Looking good!
        </.bubble_content>
        <.bubble_reactions
          side="top"
          align="start"
          role="img"
          aria-label="Reactions: party popper, clapping hands"
        >
          <span>🎉</span>
          <span>👏</span>
        </.bubble_reactions>
      </.bubble>
      <.bubble variant="destructive">
        <.bubble_content>Are you sure I can run this command?</.bubble_content>
        <.bubble_reactions>
          <.button
            variant="ghost"
            size="xs"
            phx-click="bubble_toast"
            phx-value-message="run-command"
          >
            Yes, run it
          </.button>
        </.bubble_reactions>
      </.bubble>
    </div>
    """
  end

  defp bubble_collapsible(assigns) do
    assigns =
      assign(assigns,
        bubble_collapsible_preview: @bubble_collapsible_preview,
        bubble_collapsible_text: @bubble_collapsible_text
      )

    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.bubble variant="muted">
        <.bubble_content>How can I help you today?</.bubble_content>
      </.bubble>
      <.bubble variant="muted" align="end">
        <.bubble_content>
          <.collapsible
            id="bubble-collapsible"
            composed
            class="group/collapsible whitespace-normal"
          >
            <div class="group-data-[open]/collapsible:hidden">
              <span class="whitespace-pre-line">{@bubble_collapsible_preview}</span>
            </div>
            <div class="hidden group-data-[open]/collapsible:block">
              <span class="whitespace-pre-line">{@bubble_collapsible_text}</span>
            </div>
            <.collapsible_trigger
              for="bubble-collapsible"
              class={collapsible_button_class("link", "default", "gap-1 p-0 text-muted-foreground")}
            >
              <span class="group-data-[open]/collapsible:hidden">Show more</span>
              <span class="hidden group-data-[open]/collapsible:inline">Show less</span>
              <LiveShadcn.Icon.icon
                name="chevron-down"
                data-icon="inline-end"
                class="group-data-[panel-open]/button:rotate-180"
              />
            </.collapsible_trigger>
          </.collapsible>
        </.bubble_content>
      </.bubble>
    </div>
    """
  end

  defp bubble_tooltip(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-4 py-12">
      <.bubble variant="secondary">
        <.bubble_content>Did you remove the stale route?</.bubble_content>
      </.bubble>
      <.bubble align="end">
        <.bubble_content>Yes, removed it from the registry.</.bubble_content>
        <.bubble_reactions>
          <.tooltip
            id="bubble-read-receipt"
            trigger_variant="ghost"
            trigger_size="icon-xs"
            trigger_label="Message read"
          >
            <:trigger><LiveShadcn.Icon.icon name="check" /></:trigger>
            Read on Jan 5, 2026 at 4:32 PM
          </.tooltip>
        </.bubble_reactions>
      </.bubble>
    </div>
    """
  end

  defp bubble_popover(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-4 py-12">
      <.bubble align="end">
        <.bubble_content>Run the build script.</.bubble_content>
      </.bubble>
      <.bubble variant="destructive">
        <.bubble_content>Failed to run the command.</.bubble_content>
        <.bubble_reactions>
          <.popover
            id="bubble-error-details"
            trigger_variant="ghost"
            trigger_size="icon-xs"
            trigger_label="Show error details"
            trigger_class="aria-expanded:text-destructive"
          >
            <:trigger><LiveShadcn.Icon.icon name="info" /></:trigger>
            <:title>Command failed with exit code 1</:title>
            <:description>ENOENT: no such file or directory, open pnpm-lock.yaml</:description>
          </.popover>
        </.bubble_reactions>
      </.bubble>
    </div>
    """
  end

  defp button_group_default(assigns), do: button_group_demo_example(assigns)

  defp button_group_orientation(assigns) do
    ~H"""
    <.button_group orientation="vertical" aria-label="Media controls" class="h-fit">
      <.button variant="outline" size="icon">
        <LiveShadcn.Icon.icon name="plus" />
      </.button>
      <.button variant="outline" size="icon">
        <LiveShadcn.Icon.icon name="minus" />
      </.button>
    </.button_group>
    """
  end

  defp button_group_size(assigns) do
    ~H"""
    <div class="flex flex-col items-start gap-8">
      <.button_group>
        <.button variant="outline" size="sm">Small</.button>
        <.button variant="outline" size="sm">Button</.button>
        <.button variant="outline" size="sm">Group</.button>
        <.button variant="outline" size="icon-sm">
          <LiveShadcn.Icon.icon name="plus" />
        </.button>
      </.button_group>
      <.button_group>
        <.button variant="outline">Default</.button>
        <.button variant="outline">Button</.button>
        <.button variant="outline">Group</.button>
        <.button variant="outline" size="icon">
          <LiveShadcn.Icon.icon name="plus" />
        </.button>
      </.button_group>
      <.button_group>
        <.button variant="outline" size="lg">Large</.button>
        <.button variant="outline" size="lg">Button</.button>
        <.button variant="outline" size="lg">Group</.button>
        <.button variant="outline" size="icon-lg">
          <LiveShadcn.Icon.icon name="plus" />
        </.button>
      </.button_group>
    </div>
    """
  end

  defp button_group_nested(assigns) do
    ~H"""
    <.button_group>
      <.button_group>
        <.button variant="outline" size="icon">
          <LiveShadcn.Icon.icon name="plus" />
        </.button>
      </.button_group>
      <.button_group>
        <.input_group>
          <.input_group_input placeholder="Send a message..." />
          <.tooltip
            id="button-group-nested-voice"
            trigger_as="addon-wrapper"
            trigger_align="inline-end"
            trigger_class="cn-input-group-addon flex cursor-text items-center justify-center select-none cn-input-group-addon-align-inline-end order-last"
          >
            <:trigger><LiveShadcn.Icon.icon name="audio-lines" /></:trigger>
            Voice Mode
          </.tooltip>
        </.input_group>
      </.button_group>
    </.button_group>
    """
  end

  defp button_group_separator_example(assigns) do
    ~H"""
    <.button_group>
      <.button variant="secondary" size="sm">Copy</.button>
      <.button_group_separator />
      <.button variant="secondary" size="sm">Paste</.button>
    </.button_group>
    """
  end

  defp button_group_split(assigns) do
    ~H"""
    <.button_group>
      <.button variant="secondary">Button</.button>
      <.button_group_separator />
      <.button size="icon" variant="secondary">
        <.tabler_icon name="plus" />
      </.button>
    </.button_group>
    """
  end

  defp button_group_input(assigns) do
    ~H"""
    <.button_group>
      <.input placeholder="Search..." />
      <.button variant="outline" aria-label="Search"><LiveShadcn.Icon.icon name="search" /></.button>
    </.button_group>
    """
  end

  defp button_group_input_group(assigns) do
    ~H"""
    <.button_group class="[--radius:9999rem]">
      <.button_group>
        <.button variant="outline" size="icon">
          <LiveShadcn.Icon.icon name="plus" />
        </.button>
      </.button_group>
      <.button_group>
        <.input_group>
          <.input_group_input id="button-group-message" placeholder="Send a message..." />
          <.input_group_addon align="inline-end">
            <.tooltip
              id="button-group-voice"
              trigger_as="button"
              trigger_data_size="icon-xs"
              trigger_variant="ghost"
              trigger_size="default"
              trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs data-[active=true]:bg-orange-100 data-[active=true]:text-orange-700 dark:data-[active=true]:bg-orange-800 dark:data-[active=true]:text-orange-100"
              trigger_click={button_group_voice_toggle()}
              trigger_attrs={%{"aria-pressed" => "false", "data-active" => "false"}}
            >
              <:trigger><LiveShadcn.Icon.icon name="audio-lines" /></:trigger>
              Voice Mode
            </.tooltip>
          </.input_group_addon>
        </.input_group>
      </.button_group>
    </.button_group>
    """
  end

  defp button_group_dropdown(assigns) do
    ~H"""
    <.button_group>
      <.button variant="outline">Follow</.button>
      <.dropdown_menu
        id="button-group-follow"
        direct_trigger
        align="end"
        class="w-44"
        grouped
        trigger_variant="outline"
        trigger_class="pl-2!"
      >
        <:trigger><LiveShadcn.Icon.icon name="chevron-down" /></:trigger>
        <:entry kind="item" value="mute">
          <LiveShadcn.Icon.icon name="volume-off" /> Mute Conversation
        </:entry>
        <:entry kind="item" value="mark-read">
          <LiveShadcn.Icon.icon name="check" /> Mark as Read
        </:entry>
        <:entry kind="item" value="report">
          <LiveShadcn.Icon.icon name="triangle-alert" /> Report Conversation
        </:entry>
        <:entry kind="item" value="block">
          <LiveShadcn.Icon.icon name="user-round-x" /> Block User
        </:entry>
        <:entry kind="item" value="share">
          <LiveShadcn.Icon.icon name="share" /> Share Conversation
        </:entry>
        <:entry kind="item" value="copy">
          <LiveShadcn.Icon.icon name="copy" /> Copy Conversation
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="delete" variant="destructive">
          <LiveShadcn.Icon.icon name="trash" /> Delete Conversation
        </:entry>
      </.dropdown_menu>
    </.button_group>
    """
  end

  defp button_group_select(assigns) do
    ~H"""
    <.button_group>
      <.button_group>
        <.select
          id="button-group-currency"
          value="$"
          trigger_class="font-mono"
          value_as_text={true}
          align_item_with_trigger={false}
          align="start"
        >
          <:option value="$" label="$" description="US Dollar" trigger_label="$" />
          <:option value="€" label="€" description="Euro" trigger_label="€" />
          <:option value="£" label="£" description="British Pound" trigger_label="£" />
        </.select>
        <.input placeholder="10.00" pattern="[0-9]*" />
      </.button_group>
      <.button_group>
        <.button aria-label="Send" size="icon" variant="outline">
          <LiveShadcn.Icon.icon name="arrow-right" />
        </.button>
      </.button_group>
    </.button_group>
    """
  end

  defp button_group_popover(assigns) do
    ~H"""
    <.button_group>
      <.button variant="outline"><LiveShadcn.Icon.icon name="bot" /> Copilot</.button>
      <.popover
        id="button-group-copilot"
        trigger_target="direct"
        trigger_variant="outline"
        trigger_size="icon"
        trigger_label="Open Popover"
        align="end"
        class="rounded-xl text-sm"
      >
        <:trigger><LiveShadcn.Icon.icon name="chevron-down" /></:trigger>
        <:title>Start a new task with Copilot</:title>
        <:description>Describe your task in natural language.</:description>
        <.field>
          <.field_label for="button-group-task" class="sr-only">Task Description</.field_label>
          <.textarea id="button-group-task" placeholder="I need to..." class="resize-none" />
          <.field_description>Copilot will open a pull request for review.</.field_description>
        </.field>
      </.popover>
    </.button_group>
    """
  end

  defp button_group_rtl(assigns) do
    assigns =
      assign(assigns, :button_group_rtl_label_items, [
        %{
          kind: "radio-group",
          group: "label",
          value: "personal",
          items: [
            %{value: "personal", label: "شخصي"},
            %{value: "work", label: "عمل"},
            %{value: "other", label: "آخر"}
          ]
        }
      ])

    ~H"""
    <div dir="rtl">
      <.button_group>
        <.button_group class="hidden sm:flex">
          <.button variant="outline" size="icon" aria-label="Go Back">
            <LiveShadcn.Icon.icon name="arrow-left" class="rtl:rotate-180" />
          </.button>
        </.button_group>
        <.button_group>
          <.button variant="outline">أرشفة</.button>
          <.button variant="outline">تقرير</.button>
        </.button_group>
        <.button_group>
          <.button variant="outline">تأجيل</.button>
          <.dropdown_menu
            id="button-group-rtl-more-options"
            direct_trigger
            align="start"
            class="w-40"
            grouped
            trigger_variant="outline"
            trigger_size="icon"
            trigger_attrs={%{"aria-label" => "More Options"}}
            content_attrs={%{"dir" => "rtl", "data-lang" => "ar"}}
          >
            <:trigger><LiveShadcn.Icon.icon name="ellipsis" /></:trigger>
            <:entry kind="item" value="mark-read">
              <LiveShadcn.Icon.icon name="mail-check" /> وضع علامة كمقروء
            </:entry>
            <:entry kind="item" value="archive"><LiveShadcn.Icon.icon name="archive" /> أرشفة</:entry>
            <:entry kind="separator" />
            <:entry kind="item" value="snooze"><LiveShadcn.Icon.icon name="clock" /> تأجيل</:entry>
            <:entry kind="item" value="calendar">
              <LiveShadcn.Icon.icon name="calendar-plus" /> إضافة إلى التقويم
            </:entry>
            <:entry kind="item" value="list">
              <LiveShadcn.Icon.icon name="list-filter" /> إضافة إلى القائمة
            </:entry>
            <:entry
              kind="submenu"
              value="label"
              items={@button_group_rtl_label_items}
              content_attrs={%{"dir" => "rtl", "data-lang" => "ar"}}
            >
              <LiveShadcn.Icon.icon name="tag" /> تصنيف كـ...
            </:entry>
            <:entry kind="separator" />
            <:entry kind="item" value="trash" variant="destructive">
              <LiveShadcn.Icon.icon name="trash-2" /> سلة المهملات
            </:entry>
          </.dropdown_menu>
        </.button_group>
      </.button_group>
    </div>
    """
  end

  defp button_group_voice_toggle do
    Phoenix.LiveView.JS.toggle_attribute({"aria-pressed", "true", "false"},
      to: "#button-group-voice-trigger"
    )
    |> Phoenix.LiveView.JS.toggle_attribute({"data-active", "true", "false"},
      to: "#button-group-voice-trigger"
    )
    |> Phoenix.LiveView.JS.toggle_attribute({"disabled", ""},
      to: "#button-group-message"
    )
    |> Phoenix.LiveView.JS.toggle_attribute(
      {"placeholder", "Record and send audio...", "Send a message..."},
      to: "#button-group-message"
    )
  end

  defp item_default(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-6">
      <.item variant="outline">
        <.item_content>
          <.item_title>Basic Item</.item_title>
          <.item_description>A simple item with title and description.</.item_description>
        </.item_content>
        <.item_actions>
          <.button variant="outline" size="sm">Action</.button>
        </.item_actions>
      </.item>
      <.item as="a" href="#" variant="outline" size="sm">
        <.item_media><LiveShadcn.Icon.icon name="badge-check" class="size-5" /></.item_media>
        <.item_content>
          <.item_title>Your profile has been verified.</.item_title>
        </.item_content>
        <.item_actions><LiveShadcn.Icon.icon name="chevron-right" class="size-4" /></.item_actions>
      </.item>
    </div>
    """
  end

  defp item_variant(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-6">
      <.item>
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Default Variant</.item_title>
          <.item_description>Transparent background with no border.</.item_description>
        </.item_content>
      </.item>
      <.item variant="outline">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Outline Variant</.item_title>
          <.item_description>Outlined style with a visible border.</.item_description>
        </.item_content>
      </.item>
      <.item variant="muted">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Muted Variant</.item_title>
          <.item_description>Muted background for secondary content.</.item_description>
        </.item_content>
      </.item>
    </div>
    """
  end

  defp item_size(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-6">
      <.item variant="outline">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Default Size</.item_title>
          <.item_description>The standard size for most use cases.</.item_description>
        </.item_content>
      </.item>
      <.item variant="outline" size="sm">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Small Size</.item_title>
          <.item_description>A compact size for dense layouts.</.item_description>
        </.item_content>
      </.item>
      <.item variant="outline" size="xs">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="inbox" /></.item_media>
        <.item_content>
          <.item_title>Extra Small Size</.item_title>
          <.item_description>The most compact size available.</.item_description>
        </.item_content>
      </.item>
    </div>
    """
  end

  defp item_icon(assigns) do
    ~H"""
    <div class="flex w-full max-w-lg flex-col gap-6">
      <.item variant="outline">
        <.item_media variant="icon"><LiveShadcn.Icon.icon name="shield-alert" /></.item_media>
        <.item_content>
          <.item_title>Security Alert</.item_title>
          <.item_description>New login detected from unknown device.</.item_description>
        </.item_content>
        <.item_actions><.button size="sm" variant="outline">Review</.button></.item_actions>
      </.item>
    </div>
    """
  end

  defp item_avatar(assigns) do
    ~H"""
    <div class="flex w-full max-w-lg flex-col gap-6">
      <.item variant="outline">
        <.item_media>
          <.avatar class="size-10">
            <.avatar_image src="https://github.com/evilrabbit.png" alt="" />
            <.avatar_fallback>ER</.avatar_fallback>
          </.avatar>
        </.item_media>
        <.item_content>
          <.item_title>Evil Rabbit</.item_title>
          <.item_description>Last seen 5 months ago</.item_description>
        </.item_content>
        <.item_actions>
          <.button size="icon-sm" variant="outline" class="rounded-full" aria-label="Invite">
            <LiveShadcn.Icon.icon name="plus" />
          </.button>
        </.item_actions>
      </.item>
      <.item variant="outline">
        <.item_media>
          <div class="flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale">
            <.avatar class="hidden sm:flex">
              <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
              <.avatar_fallback>CN</.avatar_fallback>
            </.avatar>
            <.avatar class="hidden sm:flex">
              <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
              <.avatar_fallback>LR</.avatar_fallback>
            </.avatar>
            <.avatar>
              <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
              <.avatar_fallback>ER</.avatar_fallback>
            </.avatar>
          </div>
        </.item_media>
        <.item_content>
          <.item_title>No Team Members</.item_title>
          <.item_description>Invite your team to collaborate on this project.</.item_description>
        </.item_content>
        <.item_actions><.button size="sm" variant="outline">Invite</.button></.item_actions>
      </.item>
    </div>
    """
  end

  defp item_image(assigns) do
    songs = [
      %{
        title: "Midnight City Lights",
        artist: "Neon Dreams",
        album: "Electric Nights",
        duration: "3:45"
      },
      %{
        title: "Coffee Shop Conversations",
        artist: "The Morning Brew",
        album: "Urban Stories",
        duration: "4:05"
      },
      %{title: "Digital Rain", artist: "Cyber Symphony", album: "Binary Beats", duration: "3:30"}
    ]

    assigns = assign(assigns, :songs, songs)

    ~H"""
    <div class="flex w-full max-w-md flex-col gap-6">
      <.item_group class="gap-4">
        <.item :for={song <- @songs} as="a" href="#" variant="outline" role="listitem">
          <.item_media variant="image">
            <img
              src={"https://avatar.vercel.sh/#{song.title}"}
              alt={song.title}
              width="32"
              height="32"
              class="object-cover grayscale"
            />
          </.item_media>
          <.item_content>
            <.item_title class="line-clamp-1">
              {song.title}
              <!-- --> -<!-- -->
              {" "}<span class="text-muted-foreground">{song.album}</span>
            </.item_title>
            <.item_description>{song.artist}</.item_description>
          </.item_content>
          <.item_content class="flex-none text-center">
            <.item_description>{song.duration}</.item_description>
          </.item_content>
        </.item>
      </.item_group>
    </div>
    """
  end

  defp item_group_example(assigns) do
    ~H"""
    <.item_group class="max-w-sm">
      <.item variant="outline">
        <.item_media>
          <.avatar>
            <.avatar_image src="https://github.com/shadcn.png" alt="" class="grayscale" /><.avatar_fallback>
              s
            </.avatar_fallback>
          </.avatar>
        </.item_media>
        <.item_content class="gap-1">
          <.item_title>shadcn</.item_title><.item_description>shadcn@vercel.com</.item_description>
        </.item_content>
        <.item_actions>
          <.button variant="ghost" size="icon" class="rounded-full"><LiveShadcn.Icon.icon name="plus" /></.button>
        </.item_actions>
      </.item>
      <.item variant="outline">
        <.item_media>
          <.avatar>
            <.avatar_image src="https://github.com/maxleiter.png" alt="" class="grayscale" /><.avatar_fallback>
              m
            </.avatar_fallback>
          </.avatar>
        </.item_media>
        <.item_content class="gap-1">
          <.item_title>maxleiter</.item_title><.item_description>
            maxleiter@vercel.com
          </.item_description>
        </.item_content>
        <.item_actions>
          <.button variant="ghost" size="icon" class="rounded-full"><LiveShadcn.Icon.icon name="plus" /></.button>
        </.item_actions>
      </.item>
      <.item variant="outline">
        <.item_media>
          <.avatar>
            <.avatar_image src="https://github.com/evilrabbit.png" alt="" class="grayscale" /><.avatar_fallback>
              e
            </.avatar_fallback>
          </.avatar>
        </.item_media>
        <.item_content class="gap-1">
          <.item_title>evilrabbit</.item_title><.item_description>
            evilrabbit@vercel.com
          </.item_description>
        </.item_content>
        <.item_actions>
          <.button variant="ghost" size="icon" class="rounded-full"><LiveShadcn.Icon.icon name="plus" /></.button>
        </.item_actions>
      </.item>
    </.item_group>
    """
  end

  defp item_header_example(assigns) do
    ~H"""
    <div class="flex w-full max-w-xl flex-col gap-6">
      <.item_group class="grid grid-cols-3 gap-4">
        <.item variant="outline">
          <.item_header>
            <img
              src="https://images.unsplash.com/photo-1650804068570-7fb2e3dbf888?q=80&w=640&auto=format&fit=crop"
              alt="v0-1.5-sm"
              width="128"
              height="128"
              class="aspect-square w-full rounded-sm object-cover"
            />
          </.item_header>
          <.item_content>
            <.item_title>v0-1.5-sm</.item_title><.item_description>
              Everyday tasks and UI generation.
            </.item_description>
          </.item_content>
        </.item>
        <.item variant="outline">
          <.item_header>
            <img
              src="https://images.unsplash.com/photo-1610280777472-54133d004c8c?q=80&w=640&auto=format&fit=crop"
              alt="v0-1.5-lg"
              width="128"
              height="128"
              class="aspect-square w-full rounded-sm object-cover"
            />
          </.item_header>
          <.item_content>
            <.item_title>v0-1.5-lg</.item_title><.item_description>
              Advanced thinking or reasoning.
            </.item_description>
          </.item_content>
        </.item>
        <.item variant="outline">
          <.item_header>
            <img
              src="https://images.unsplash.com/photo-1602146057681-08560aee8cde?q=80&w=640&auto=format&fit=crop"
              alt="v0-2.0-mini"
              width="128"
              height="128"
              class="aspect-square w-full rounded-sm object-cover"
            />
          </.item_header>
          <.item_content>
            <.item_title>v0-2.0-mini</.item_title><.item_description>
              Open Source model for everyone.
            </.item_description>
          </.item_content>
        </.item>
      </.item_group>
    </div>
    """
  end

  defp item_link(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-4">
      <.item as="a" href="#">
        <.item_content>
          <.item_title>Visit our documentation</.item_title>
          <.item_description>Learn how to get started with our components.</.item_description>
        </.item_content>
        <.item_actions><LiveShadcn.Icon.icon name="chevron-right" class="size-4" /></.item_actions>
      </.item>
      <.item as="a" href="#" target="_blank" rel="noopener noreferrer" variant="outline">
        <.item_content>
          <.item_title>External resource</.item_title>
          <.item_description>Opens in a new tab with security attributes.</.item_description>
        </.item_content>
        <.item_actions><LiveShadcn.Icon.icon name="external-link" class="size-4" /></.item_actions>
      </.item>
    </div>
    """
  end

  defp item_dropdown(assigns) do
    ~H"""
    <.dropdown_menu id="item-dropdown" trigger_variant="outline" class="w-48" align="end" grouped>
      <:trigger>Select <LiveShadcn.Icon.icon name="chevron-down" /></:trigger>
      <:entry kind="item" value="shadcn">
        <.item size="xs" class="w-full p-2">
          <.item_media>
            <.avatar class="size-[--spacing(6.5)]">
              <.avatar_image src="https://github.com/shadcn.png" alt="" class="grayscale" /><.avatar_fallback>
                s
              </.avatar_fallback>
            </.avatar>
          </.item_media>
          <.item_content class="gap-0">
            <.item_title>shadcn</.item_title><.item_description class="leading-none">
              shadcn@vercel.com
            </.item_description>
          </.item_content>
        </.item>
      </:entry>
      <:entry kind="item" value="maxleiter">
        <.item size="xs" class="w-full p-2">
          <.item_media>
            <.avatar class="size-[--spacing(6.5)]">
              <.avatar_image src="https://github.com/maxleiter.png" alt="" class="grayscale" /><.avatar_fallback>
                m
              </.avatar_fallback>
            </.avatar>
          </.item_media>
          <.item_content class="gap-0">
            <.item_title>maxleiter</.item_title><.item_description class="leading-none">
              maxleiter@vercel.com
            </.item_description>
          </.item_content>
        </.item>
      </:entry>
      <:entry kind="item" value="evilrabbit">
        <.item size="xs" class="w-full p-2">
          <.item_media>
            <.avatar class="size-[--spacing(6.5)]">
              <.avatar_image src="https://github.com/evilrabbit.png" alt="" class="grayscale" /><.avatar_fallback>
                e
              </.avatar_fallback>
            </.avatar>
          </.item_media>
          <.item_content class="gap-0">
            <.item_title>evilrabbit</.item_title><.item_description class="leading-none">
              evilrabbit@vercel.com
            </.item_description>
          </.item_content>
        </.item>
      </:entry>
    </.dropdown_menu>
    """
  end

  defp item_rtl(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-6" dir="rtl">
      <.item variant="outline" dir="rtl">
        <.item_content>
          <.item_title>عنصر أساسي</.item_title>
          <.item_description>عنصر بسيط يحتوي على عنوان ووصف.</.item_description>
        </.item_content>
        <.item_actions><.button variant="outline" size="sm">إجراء</.button></.item_actions>
      </.item>
      <.item as="a" href="#" variant="outline" size="sm" dir="rtl">
        <.item_media><LiveShadcn.Icon.icon name="badge-check" class="size-5" /></.item_media>
        <.item_content>
          <.item_title>تم التحقق من ملفك الشخصي.</.item_title>
        </.item_content>
        <.item_actions><LiveShadcn.Icon.icon name="chevron-right" class="size-4" /></.item_actions>
      </.item>
    </div>
    """
  end

  defp marker_default(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker>
        <.marker_icon><LiveShadcn.Icon.icon name="git-branch" /></.marker_icon>
        <.marker_content>Switched to a new branch</.marker_content>
      </.marker>
      <.marker role="status">
        <.marker_icon><.spinner /></.marker_icon>
        <.marker_content class="shimmer">Thinking...</.marker_content>
      </.marker>
      <.marker variant="separator">
        <.marker_content>Conversation compacted</.marker_content>
      </.marker>
      <.marker>
        <.marker_icon><LiveShadcn.Icon.icon name="search" /></.marker_icon>
        <.marker_content>Explored 4 files</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_variants(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker>
        <.marker_content>A default marker for inline notes.</.marker_content>
      </.marker>
      <.marker variant="separator">
        <.marker_content>A separator marker</.marker_content>
      </.marker>
      <.marker variant="border">
        <.marker_content>A border marker for row boundaries.</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_status(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker role="status">
        <.marker_icon><.spinner /></.marker_icon>
        <.marker_content>Compacting conversation</.marker_content>
      </.marker>
      <.marker variant="separator" role="status">
        <.marker_icon><.spinner /></.marker_icon>
        <.marker_content>Running tests</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_shimmer(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker role="status">
        <.marker_content class="shimmer">Thinking...</.marker_content>
      </.marker>
      <.marker variant="separator" role="status">
        <.marker_content class="shimmer">Reading 4 files</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_separator(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker variant="separator">
        <.marker_content>Today</.marker_content>
      </.marker>
      <.marker variant="separator">
        <.marker_content>Worked for 42s</.marker_content>
      </.marker>
      <.marker variant="separator">
        <.marker_content>Conversation compacted</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_border(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-3 py-12">
      <.marker variant="border">
        <.marker_icon><LiveShadcn.Icon.icon name="git-branch" /></.marker_icon>
        <.marker_content>Switched to release-candidate</.marker_content>
      </.marker>
      <.marker variant="border">
        <.marker_icon><LiveShadcn.Icon.icon name="search" /></.marker_icon>
        <.marker_content>Reviewed 8 related files</.marker_content>
      </.marker>
      <.marker variant="border">
        <.marker_icon><LiveShadcn.Icon.icon name="file-text" /></.marker_icon>
        <.marker_content>Opened implementation notes</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_icon_example(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-12 py-12">
      <.marker>
        <.marker_icon><LiveShadcn.Icon.icon name="git-branch" /></.marker_icon>
        <.marker_content>Switched to a new branch</.marker_content>
      </.marker>
      <.marker variant="separator">
        <.marker_icon><LiveShadcn.Icon.icon name="search" /></.marker_icon>
        <.marker_content>Explored 4 files</.marker_content>
      </.marker>
      <.marker class="flex-col">
        <.marker_icon><LiveShadcn.Icon.icon name="book-open-check" /></.marker_icon>
        <.marker_content>Syncing completed</.marker_content>
      </.marker>
    </div>
    """
  end

  defp marker_link_button(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.marker comp="a" href="#links-and-buttons">
        <.marker_icon><LiveShadcn.Icon.icon name="git-branch" /></.marker_icon>
        <.marker_content>View the pull request</.marker_content>
      </.marker>
      <.marker
        comp="button"
        type="button"
        class="transition-colors hover:text-foreground"
        phx-click="toast_add"
        phx-value-example="marker"
      >
        <.marker_icon><LiveShadcn.Icon.icon name="rotate-ccw" /></.marker_icon>
        <.marker_content>Revert this change</.marker_content>
      </.marker>
    </div>
    <Sonner.toaster id="toast-marker" dismiss="dismiss_toast" duration={0}>
      <:toast
        :for={notice <- @toast_examples["marker"]}
        id={notice.id}
        type={notice.type}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </Sonner.toaster>
    """
  end

  defp message_default(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-6 py-12">
      <.message align="end">
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/10.png" alt="@me" />
            <.avatar_fallback>ME</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble>
            <.bubble_content>Deploying to prod real quick.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message>
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/02.png" alt="@rabbit" />
            <.avatar_fallback>R</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble variant="muted">
            <.bubble_content>It's 4:55 PM. On a Friday.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message align="end">
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/10.png" alt="@me" />
            <.avatar_fallback>ME</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble>
            <.bubble_content>It's a one-line change.</.bubble_content>
          </.bubble>
          <.message_footer>Delivered</.message_footer>
        </.message_content>
      </.message>
      <.message>
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/02.png" alt="@rabbit" />
            <.avatar_fallback>R</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble_group>
            <.bubble variant="muted">
              <.bubble_content>It's always a one-line change 😭.</.bubble_content>
            </.bubble>
            <.bubble variant="muted">
              <.bubble_content>Alright, let me take a look.</.bubble_content>
              <.bubble_reactions aria-label="Reactions: thumbs up">
                <span>👍</span>
              </.bubble_reactions>
            </.bubble>
          </.bubble_group>
        </.message_content>
      </.message>
      <.marker role="status">
        <.marker_content class="shimmer">
          <span class="font-medium">Oliver</span> is typing...
        </.marker_content>
      </.marker>
    </div>
    """
  end

  defp message_avatar_example(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-6 py-12">
      <.message>
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/03.png" alt="@avatar" />
            <.avatar_fallback>R</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble variant="muted">
            <.bubble_content>The build failed during dependency installation.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message align="end">
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/10.png" alt="@avatar" />
            <.avatar_fallback>R</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble>
            <.bubble_content>Can you share the exact error?</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message>
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/03.png" alt="@avatar" />
            <.avatar_fallback>R</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble_group>
            <.bubble variant="muted">
              <.bubble_content>Here's the error from the logs</.bubble_content>
            </.bubble>
            <.bubble variant="muted">
              <.bubble_content>
                Something went wrong with the build. The libraries are not installed correctly. Try running the build again.
              </.bubble_content>
            </.bubble>
          </.bubble_group>
        </.message_content>
      </.message>
    </div>
    """
  end

  defp message_group_example(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-6 py-12">
      <.message_group>
        <.message>
          <.message_avatar />
          <.message_content>
            <.bubble variant="muted">
              <.bubble_content>I checked the registry addresses.</.bubble_content>
            </.bubble>
          </.message_content>
        </.message>
        <.message>
          <.message_avatar>
            <.avatar>
              <.avatar_image src="/avatars/02.png" alt="@avatar" />
              <.avatar_fallback>CN</.avatar_fallback>
            </.avatar>
          </.message_avatar>
          <.message_content>
            <.bubble variant="muted">
              <.bubble_content>
                The component and example JSON now live under the UI registry.
              </.bubble_content>
            </.bubble>
          </.message_content>
        </.message>
      </.message_group>
    </div>
    """
  end

  defp message_header_footer(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.message>
        <.message_content>
          <.message_header>Olivia</.message_header>
          <.bubble variant="muted">
            <.bubble_content>I already checked the logs.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message align="end">
        <.message_content>
          <.bubble>
            <.bubble_content>
              Send the report to the team. Ping @shadcn if you need help.
            </.bubble_content>
          </.bubble>
          <.message_footer>
            <div>Read <span class="font-normal">Yesterday</span></div>
          </.message_footer>
        </.message_content>
      </.message>
    </div>
    """
  end

  defp message_actions(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.message>
        <.message_content>
          <.bubble variant="muted">
            <.bubble_content>
              The install failure is coming from the workspace package.
            </.bubble_content>
          </.bubble>
          <.message_footer>
            <.button variant="ghost" size="icon" aria-label="Copy" title="Copy">
              <LiveShadcn.Icon.icon name="copy" />
            </.button>
            <.button variant="ghost" size="icon" aria-label="Like" title="Like">
              <LiveShadcn.Icon.icon name="thumbs-up" />
            </.button>
            <.button variant="ghost" size="icon" aria-label="Dislike" title="Dislike">
              <LiveShadcn.Icon.icon name="thumbs-down" />
            </.button>
          </.message_footer>
        </.message_content>
      </.message>
      <.message align="end">
        <.message_content>
          <.bubble>
            <.bubble_content>Okay drop me a link. Taking a look...</.bubble_content>
          </.bubble>
          <.message_footer class="gap-2">
            <span class="font-normal text-destructive">Failed to send</span>
            <.button variant="ghost" size="icon-xs" title="Retry" aria-label="Retry">
              <LiveShadcn.Icon.icon name="refresh-ccw" />
            </.button>
          </.message_footer>
        </.message_content>
      </.message>
    </div>
    """
  end

  defp message_attachment(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <.message align="end">
        <.message_content>
          <.attachment orientation="vertical">
            <.attachment_media variant="image">
              <img
                src="https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80"
                alt="Workspace"
              />
            </.attachment_media>
          </.attachment>
          <.bubble>
            <.bubble_content>
              Here's the image. Can you add it to the PDF? Use it for the cover page.
            </.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message>
        <.message_content>
          <.bubble variant="muted">
            <.bubble_content>
              Done. Here's the PDF with the image added as the cover page.
            </.bubble_content>
          </.bubble>
          <.attachment>
            <.attachment_media><LiveShadcn.Icon.icon name="file-text" /></.attachment_media>
            <.attachment_content>
              <.attachment_title>sales-dashboard.pdf</.attachment_title>
              <.attachment_description>PDF · 2.4 MB</.attachment_description>
            </.attachment_content>
            <.attachment_actions>
              <.attachment_action
                type="button"
                title="Download"
                aria-label="Download"
                size="icon-sm"
                variant="secondary"
              >
                <LiveShadcn.Icon.icon name="download" />
              </.attachment_action>
            </.attachment_actions>
          </.attachment>
        </.message_content>
      </.message>
      <.message align="end">
        <.message_content>
          <.bubble>
            <.bubble_content>Thanks. Looks good.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
    </div>
    """
  end

  defp pagination_default(assigns) do
    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous href="#" />
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#">1</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#" is_active>2</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#">3</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_ellipsis />
        </.pagination_item>
        <.pagination_item>
          <.pagination_next href="#" />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  defp pagination_simple(assigns) do
    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item :for={page <- 1..5}>
          <.pagination_link href="#" is_active={page == 2}>{page}</.pagination_link>
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  defp pagination_icons_only(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-4">
      <.field orientation="horizontal" class="w-fit">
        <.field_label for="select-rows-per-page-trigger">Rows per page</.field_label>
        <.select id="select-rows-per-page" value="25" align="start" trigger_class="w-20">
          <:option value="10" label="10" />
          <:option value="25" label="25" />
          <:option value="50" label="50" />
          <:option value="100" label="100" />
        </.select>
      </.field>
      <.pagination class="mx-0 w-auto">
        <.pagination_content>
          <.pagination_item>
            <.pagination_previous href="#" />
          </.pagination_item>
          <.pagination_item>
            <.pagination_next href="#" />
          </.pagination_item>
        </.pagination_content>
      </.pagination>
    </div>
    """
  end

  defp pagination_rtl(assigns) do
    ~H"""
    <.pagination dir="rtl">
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous href="#" text="السابق" />
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#">١</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#" is_active>٢</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#">٣</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_ellipsis />
        </.pagination_item>
        <.pagination_item>
          <.pagination_next href="#" text="التالي" />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  defp carousel_default(assigns) do
    ~H"""
    <.carousel id="carousel-default" class="w-full max-w-[12rem] sm:max-w-xs">
      <.carousel_content>
        <.carousel_item :for={index <- 1..5}>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  defp carousel_size(assigns) do
    ~H"""
    <.carousel
      id="carousel-size"
      align="start"
      class="w-full max-w-[12rem] sm:max-w-xs md:max-w-sm"
    >
      <.carousel_content>
        <.carousel_item :for={index <- 1..5} class="basis-1/2 lg:basis-1/3">
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-3xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  defp carousel_spacing(assigns) do
    ~H"""
    <.carousel id="carousel-spacing" class="w-full max-w-[12rem] sm:max-w-xs md:max-w-sm">
      <.carousel_content class="-ml-1">
        <.carousel_item :for={index <- 1..5} class="basis-1/2 pl-1 lg:basis-1/3">
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-2xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  defp carousel_orientation(assigns) do
    ~H"""
    <.carousel
      id="carousel-orientation"
      align="start"
      orientation="vertical"
      class="w-full max-w-xs"
    >
      <.carousel_content orientation="vertical" class="-mt-1 h-[270px]">
        <.carousel_item
          :for={index <- 1..5}
          orientation="vertical"
          class="basis-1/2 pt-1"
        >
          <div class="p-1">
            <.card>
              <.card_content class="flex items-center justify-center p-6">
                <span class="text-3xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous orientation="vertical" />
      <.carousel_next orientation="vertical" />
    </.carousel>
    """
  end

  defp carousel_api(assigns) do
    ~H"""
    <div class="mx-auto max-w-[10rem] sm:max-w-xs">
      <.carousel id="carousel-api" class="w-full max-w-xs">
        <.carousel_content>
          <.carousel_item :for={index <- 1..5}>
            <.card class="m-px">
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </.carousel_item>
        </.carousel_content>
        <.carousel_previous />
        <.carousel_next />
      </.carousel>
      <div
        data-lb-carousel-status="carousel-api"
        class="py-2 text-center text-sm text-muted-foreground"
      >
        Slide 1 of 5
      </div>
    </div>
    """
  end

  defp carousel_plugin(assigns) do
    ~H"""
    <.carousel
      id="carousel-plugin"
      autoplay={2000}
      class="w-full max-w-[10rem] sm:max-w-xs"
    >
      <.carousel_content>
        <.carousel_item :for={index <- 1..5}>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  defp carousel_rtl(assigns) do
    ~H"""
    <.carousel
      id="carousel-rtl"
      dir="rtl"
      direction="rtl"
      class="w-full max-w-[12rem] sm:max-w-xs"
    >
      <.carousel_content>
        <.carousel_item :for={number <- ["١", "٢", "٣", "٤", "٥"]}>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">{number}</span>
              </.card_content>
            </.card>
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
      mode="single"
      selected={@calendar_reference_date}
      class="rounded-lg border"
      caption_layout="dropdown"
    />
    """
  end

  defp calendar_hijri(assigns) do
    ~H"""
    <div class="font-vazirmatn">
      <.calendar
        id="calendar-hijri"
        mode="single"
        default_month={~D[2025-06-12]}
        selected={~D[2025-06-12]}
        calendar="persian"
        locale="fa"
        week_starts_on={6}
        class="rounded-lg border"
      />
    </div>
    """
  end

  defp calendar_basic(assigns) do
    ~H"""
    <.calendar
      id="calendar-basic"
      mode="single"
      default_month={@calendar_reference_date}
      class="rounded-lg border"
    />
    """
  end

  defp calendar_multiple(assigns) do
    ~H"""
    <.card class="mx-auto w-fit p-0">
      <.card_content class="p-0">
        <.calendar
          id="calendar-multiple"
          mode="multiple"
          default_month={@calendar_reference_date}
        />
      </.card_content>
    </.card>
    """
  end

  defp calendar_range(assigns) do
    range_start = calendar_year_date(assigns.calendar_reference_date, 1, 12)
    assigns = assign(assigns, range_start: range_start, range_end: Date.add(range_start, 30))

    ~H"""
    <.calendar
      id="calendar-range"
      mode="range"
      default_month={@range_start}
      selected={%{from: @range_start, to: @range_end}}
      number_of_months={2}
      class="rounded-lg border"
    />
    """
  end

  defp calendar_caption(assigns) do
    ~H"""
    <.calendar
      id="calendar-caption"
      mode="single"
      default_month={@calendar_reference_date}
      caption_layout="dropdown"
      class="rounded-lg border"
    />
    """
  end

  defp calendar_presets(assigns) do
    ~H"""
    <.card size="sm" class="mx-auto w-fit max-w-[300px]">
      <.card_content>
        <.calendar
          id="calendar-presets"
          mode="single"
          selected={@calendar_presets_date}
          month={@calendar_presets_month}
          on_select="calendar_presets_select"
          on_month_change="calendar_presets_month_change"
          fixed_weeks
          day_group={false}
          day_group_after_select
          class="p-0 [--cell-size:--spacing(9.5)]"
        />
      </.card_content>
      <.card_footer class="flex flex-wrap gap-2 border-t">
        <.button
          :for={
            {label, days} <- [
              {"Today", 0},
              {"Tomorrow", 1},
              {"In 3 days", 3},
              {"In a week", 7},
              {"In 2 weeks", 14}
            ]
          }
          variant="outline"
          size="sm"
          shrink={false}
          class="flex-1"
          phx-click="calendar_preset"
          phx-value-days={days}
        >
          {label}
        </.button>
      </.card_footer>
    </.card>
    """
  end

  defp calendar_time(assigns) do
    assigns = assign(assigns, date: calendar_month_day(assigns.calendar_reference_date, 12))

    ~H"""
    <.card size="sm" class="mx-auto w-fit">
      <.card_content>
        <.calendar id="calendar-time" mode="single" selected={@date} class="p-0" />
      </.card_content>
      <.card_footer class="border-t bg-card">
        <.field_group>
          <.field>
            <.field_label for="time-from">Start Time</.field_label>
            <.input_group>
              <.input_group_input
                id="time-from"
                type="time"
                step="1"
                value="10:30:00"
                class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
              />
              <.input_group_addon>
                <LiveShadcn.Icon.icon name="clock-2" class="text-muted-foreground" />
              </.input_group_addon>
            </.input_group>
          </.field>
          <.field>
            <.field_label for="time-to">End Time</.field_label>
            <.input_group>
              <.input_group_input
                id="time-to"
                type="time"
                step="1"
                value="12:30:00"
                class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
              />
              <.input_group_addon>
                <LiveShadcn.Icon.icon name="clock-2" class="text-muted-foreground" />
              </.input_group_addon>
            </.input_group>
          </.field>
        </.field_group>
      </.card_footer>
    </.card>
    """
  end

  defp calendar_booked_dates(assigns) do
    selected = calendar_year_date(assigns.calendar_reference_date, 1, 6)
    booked_dates = Enum.map(12..26, &calendar_year_date(assigns.calendar_reference_date, 1, &1))
    assigns = assign(assigns, selected: selected, booked_dates: booked_dates)

    ~H"""
    <.card class="mx-auto w-fit p-0">
      <.card_content class="p-0">
        <.calendar
          id="calendar-booked-dates"
          mode="single"
          default_month={@selected}
          selected={@selected}
          disabled={@booked_dates}
          modifiers={%{booked: @booked_dates}}
          modifiers_class_names={%{booked: "[&>button]:line-through opacity-100"}}
        />
      </.card_content>
    </.card>
    """
  end

  defp calendar_custom_days(assigns) do
    range_start = calendar_year_date(assigns.calendar_reference_date, 12, 8)
    assigns = assign(assigns, range_start: range_start, range_end: Date.add(range_start, 10))

    ~H"""
    <.card class="mx-auto w-fit p-0">
      <.card_content class="p-0">
        <.calendar
          id="calendar-custom-days"
          mode="range"
          default_month={@range_start}
          selected={%{from: @range_start, to: @range_end}}
          number_of_months={1}
          caption_layout="dropdown"
          caption_month_format="long"
          day_extra="price"
          class="[--cell-size:--spacing(10)] md:[--cell-size:--spacing(12)]"
        />
      </.card_content>
    </.card>
    """
  end

  defp calendar_week_numbers(assigns) do
    assigns =
      assign(assigns, selected: calendar_year_date(assigns.calendar_reference_date, 1, 12))

    ~H"""
    <.card class="mx-auto w-fit p-0">
      <.card_content class="p-0">
        <.calendar
          id="calendar-week-numbers"
          mode="single"
          default_month={@selected}
          selected={@selected}
          show_week_number
        />
      </.card_content>
    </.card>
    """
  end

  defp calendar_rtl(assigns) do
    ~H"""
    <.calendar
      id="calendar-rtl"
      mode="single"
      selected={@calendar_reference_date}
      caption_layout="dropdown"
      dir="rtl"
      locale="ar"
      class="rounded-lg border [--cell-size:--spacing(9)]"
    />
    """
  end

  defp date_picker_demo(assigns) do
    date = assigns.date_picker["default"]

    assigns =
      assign(assigns,
        date: date,
        reference_date: assigns.date_picker_reference_date,
        label: date_picker_long(date, "Pick a date")
      )

    ~H"""
    <.popover
      id="date-picker-demo"
      trigger_target="direct"
      align="start"
      class="w-auto p-0"
      trigger_rest={%{"data-empty" => to_string(is_nil(@date))}}
      trigger_class="w-[212px] justify-between text-left font-normal data-[empty=true]:text-muted-foreground"
    >
      <:trigger>{@label}<LiveShadcn.Icon.icon name="chevron-down" data-icon="inline-end" /></:trigger>
      <.calendar
        id="date-picker-demo-calendar"
        mode="single"
        selected={@date}
        default_month={@date || @reference_date}
        on_select="date_picker_default_select"
      />
    </.popover>
    """
  end

  defp date_picker_basic(assigns) do
    date = assigns.date_picker["basic"]

    assigns =
      assign(assigns,
        date: date,
        reference_date: assigns.date_picker_reference_date,
        label: date_picker_long(date, "Pick a date")
      )

    ~H"""
    <.field class="mx-auto w-44">
      <.field_label for="date-picker-basic-trigger">Date</.field_label>
      <.popover
        id="date-picker-basic"
        trigger_target="direct"
        align="start"
        class="w-auto p-0"
        trigger_class="justify-start font-normal"
      >
        <:trigger>{@label}</:trigger>
        <.calendar
          id="date-picker-basic-calendar"
          mode="single"
          selected={@date}
          default_month={@date || @reference_date}
          on_select="date_picker_basic_select"
        />
      </.popover>
    </.field>
    """
  end

  defp date_picker_range(assigns) do
    range = assigns.date_picker["range"]
    assigns = assign(assigns, range: range, label: date_picker_range_label(range))

    ~H"""
    <.field class="mx-auto w-60">
      <.field_label for="date-picker-range-trigger">Date Picker Range</.field_label>
      <.popover
        id="date-picker-range"
        trigger_target="direct"
        align="start"
        class="w-auto p-0"
        trigger_class="justify-start px-2.5 font-normal"
      >
        <:trigger>
          <LiveShadcn.Icon.icon name="calendar" data-icon="inline-start" /> {@label}
        </:trigger>
        <.calendar
          id="date-picker-range-calendar"
          mode="range"
          selected={@range}
          default_month={@range.from}
          number_of_months={2}
          on_select="date_picker_range_select"
        />
      </.popover>
    </.field>
    """
  end

  defp date_picker_dob(assigns) do
    date = assigns.date_picker["dob"]

    assigns =
      assign(assigns,
        date: date,
        reference_date: assigns.date_picker_reference_date,
        label: if(date, do: date_picker_dob_value(date), else: "Select date")
      )

    ~H"""
    <.field class="mx-auto w-44">
      <.field_label for="date-picker-dob-trigger">Date of birth</.field_label>
      <.popover
        id="date-picker-dob"
        align="start"
        class="w-auto overflow-hidden p-0"
        trigger_class="justify-start font-normal"
      >
        <:trigger>{@label}</:trigger>
        <.calendar
          id="date-picker-dob-calendar"
          mode="single"
          selected={@date}
          default_month={@date || @reference_date}
          caption_layout="dropdown"
          on_select="date_picker_dob_select"
          on_select_js={LiveBase.Popover.close("date-picker-dob")}
        />
      </.popover>
    </.field>
    """
  end

  defp date_picker_input(assigns) do
    date = assigns.date_picker["input"]

    assigns =
      assign(assigns,
        date: date,
        value: assigns.date_picker_values["input"],
        selection: assigns.date_picker_selection_versions["input"]
      )

    ~H"""
    <.field class="mx-auto w-48">
      <.field_label for="date-required">Subscription Date</.field_label>
      <form
        id="date-picker-input-form"
        class="contents"
        phx-change="date_picker_input"
        phx-value-example="input"
      >
        <.input_group>
          <.input_group_input
            id="date-required"
            value={@value}
            placeholder="June 01, 2025"
            phx-key="ArrowDown"
            phx-keydown={
              LiveBase.Popover.open(%Phoenix.LiveView.JS{}, "date-picker-input", focus: false)
            }
            phx-hook="DatePickerInput"
            data-date-picker-selection={@selection}
            data-date-picker-value={@value}
            data-date-picker-focus-target="date-required"
            name="value"
          />
          <.input_group_addon align="inline-end">
            <.popover
              id="date-picker-input"
              trigger_target="direct"
              trigger_component="input-group-button"
              return_focus_to_trigger
              align="end"
              align_offset={-8}
              side_offset={10}
              class="w-auto overflow-hidden p-0"
              trigger_label="Select date"
              trigger_variant="ghost"
              trigger_size="icon-xs"
            >
              <:trigger>
                <LiveShadcn.Icon.icon name="calendar" /><span class="sr-only">Select date</span>
              </:trigger>
              <.calendar
                id="date-picker-input-calendar"
                mode="single"
                selected={@date}
                month={@date}
                on_select="date_picker_input_select"
                return_focus="date-required"
                on_select_js={LiveBase.Popover.close("date-picker-input")}
              />
            </.popover>
          </.input_group_addon>
        </.input_group>
      </form>
    </.field>
    """
  end

  defp date_picker_time(assigns) do
    date = assigns.date_picker["time"]

    assigns =
      assign(assigns,
        date: date,
        reference_date: assigns.date_picker_reference_date,
        label: date_picker_long(date, "Select date")
      )

    ~H"""
    <.field_group class="mx-auto max-w-xs flex-row">
      <.field>
        <.field_label for="date-picker-time-trigger">Date</.field_label>
        <.popover
          id="date-picker-time"
          trigger_target="direct"
          align="start"
          class="w-auto overflow-hidden p-0"
          trigger_class="w-32 justify-between font-normal"
        >
          <:trigger>
            {@label}<LiveShadcn.Icon.icon name="chevron-down" data-icon="inline-end" />
          </:trigger>
          <.calendar
            id="date-picker-time-calendar"
            mode="single"
            selected={@date}
            default_month={@date || @reference_date}
            caption_layout="dropdown"
            on_select="date_picker_time_select"
            on_select_js={LiveBase.Popover.close("date-picker-time")}
          />
        </.popover>
      </.field><.field class="w-32">
        <.field_label for="time-picker-optional">Time</.field_label><.input
          type="time"
          id="time-picker-optional"
          step="1"
          value="10:30:00"
          class="appearance-none bg-background [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
        />
      </.field>
    </.field_group>
    """
  end

  defp date_picker_natural_language(assigns) do
    date = assigns.date_picker["natural-language"]

    assigns =
      assign(assigns,
        date: date,
        value: assigns.date_picker_values["natural-language"],
        label: date_picker_input_value(date),
        selection: assigns.date_picker_selection_versions["natural-language"]
      )

    ~H"""
    <.field class="mx-auto max-w-xs">
      <.field_label for="date-optional">Schedule Date</.field_label>
      <form
        id="date-picker-natural-language-form"
        class="contents"
        phx-change="date_picker_input"
        phx-value-example="natural-language"
      >
        <.input_group>
          <.input_group_input
            id="date-optional"
            value={@value}
            placeholder="Tomorrow or next week"
            phx-key="ArrowDown"
            phx-keydown={
              LiveBase.Popover.open(%Phoenix.LiveView.JS{}, "date-picker-natural-language",
                focus: false
              )
            }
            phx-hook="DatePickerInput"
            data-date-picker-selection={@selection}
            data-date-picker-value={@value}
            data-date-picker-focus-target="date-optional"
            name="value"
          />
          <.input_group_addon align="inline-end">
            <.popover
              id="date-picker-natural-language"
              trigger_target="direct"
              trigger_component="input-group-button"
              return_focus_to_trigger
              align="end"
              side_offset={8}
              class="w-auto overflow-hidden p-0"
              trigger_label="Select date"
              trigger_variant="ghost"
              trigger_size="icon-xs"
            >
              <:trigger>
                <LiveShadcn.Icon.icon name="calendar" /><span class="sr-only">Select date</span>
              </:trigger>
              <.calendar
                id="date-picker-natural-language-calendar"
                mode="single"
                selected={@date}
                default_month={@date}
                caption_layout="dropdown"
                on_select="date_picker_natural_language_select"
                return_focus="date-optional"
                on_select_js={LiveBase.Popover.close("date-picker-natural-language")}
              />
            </.popover>
          </.input_group_addon>
        </.input_group>
      </form><div class="px-1 text-sm text-muted-foreground">
        Your post will be published on<!-- -->
        <span class="font-medium">{@label}</span>.
      </div>
    </.field>
    """
  end

  defp date_picker_rtl(assigns) do
    date = assigns.date_picker["rtl"]

    assigns =
      assign(assigns,
        date: date,
        reference_date: assigns.date_picker_reference_date,
        label: date_picker_arabic(date, "اختر تاريخًا")
      )

    ~H"""
    <.popover
      id="date-picker-rtl"
      trigger_target="direct"
      align="start"
      dir="rtl"
      trigger_dir="rtl"
      class="w-auto p-0"
      trigger_rest={%{"data-empty" => to_string(is_nil(@date))}}
      trigger_class="w-[212px] justify-between text-left font-normal data-[empty=true]:text-muted-foreground"
    >
      <:trigger>{@label}<LiveShadcn.Icon.icon name="chevron-down" data-icon="inline-end" /></:trigger>
      <.calendar
        id="date-picker-rtl-calendar"
        mode="single"
        selected={@date}
        default_month={@date || @reference_date}
        on_select="date_picker_rtl_select"
        dir="rtl"
        locale="ar"
      />
    </.popover>
    """
  end

  defp date_picker_long(nil, fallback), do: fallback

  defp date_picker_long(date, _fallback) do
    Calendar.strftime(date, "%B") <>
      " " <>
      Integer.to_string(date.day) <>
      date_picker_ordinal(date.day) <> Calendar.strftime(date, ", %Y")
  end

  defp date_picker_input_value(nil), do: ""
  defp date_picker_input_value(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp date_picker_dob_value(date) do
    Integer.to_string(date.month) <>
      "/" <>
      Integer.to_string(date.day) <>
      "/" <>
      Integer.to_string(date.year)
  end

  defp date_picker_ordinal(day) when rem(day, 100) in 11..13, do: "th"
  defp date_picker_ordinal(day) when rem(day, 10) == 1, do: "st"
  defp date_picker_ordinal(day) when rem(day, 10) == 2, do: "nd"
  defp date_picker_ordinal(day) when rem(day, 10) == 3, do: "rd"
  defp date_picker_ordinal(_day), do: "th"

  defp date_picker_arabic(nil, fallback), do: fallback

  defp date_picker_arabic(date, _fallback) do
    Enum.at(
      ~w(يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر),
      date.month - 1
    ) <> " " <> Integer.to_string(date.day) <> ", " <> Integer.to_string(date.year)
  end

  defp date_picker_range_label(%{from: from, to: to}) when not is_nil(to),
    do: Calendar.strftime(from, "%b %d, %Y") <> " - " <> Calendar.strftime(to, "%b %d, %Y")

  defp date_picker_range_label(%{from: from}), do: Calendar.strftime(from, "%b %d, %Y")
  defp date_picker_range_label(_), do: "Pick a date"

  defp calendar_year_date(reference_date, month, day),
    do: Date.new!(reference_date.year, month, day)

  defp date_picker_year_date(reference_date, month, day),
    do: Date.new!(reference_date.year, month, day)

  defp calendar_month_day(reference_date, day),
    do: Date.new!(reference_date.year, reference_date.month, day)

  defp calendar_month_start(date), do: Date.new!(date.year, date.month, 1)

  @chart_demo_data [
    {"2024-04-01", 222, 150},
    {"2024-04-02", 97, 180},
    {"2024-04-03", 167, 120},
    {"2024-04-04", 242, 260},
    {"2024-04-05", 373, 290},
    {"2024-04-06", 301, 340},
    {"2024-04-07", 245, 180},
    {"2024-04-08", 409, 320},
    {"2024-04-09", 59, 110},
    {"2024-04-10", 261, 190},
    {"2024-04-11", 327, 350},
    {"2024-04-12", 292, 210},
    {"2024-04-13", 342, 380},
    {"2024-04-14", 137, 220},
    {"2024-04-15", 120, 170},
    {"2024-04-16", 138, 190},
    {"2024-04-17", 446, 360},
    {"2024-04-18", 364, 410},
    {"2024-04-19", 243, 180},
    {"2024-04-20", 89, 150},
    {"2024-04-21", 137, 200},
    {"2024-04-22", 224, 170},
    {"2024-04-23", 138, 230},
    {"2024-04-24", 387, 290},
    {"2024-04-25", 215, 250},
    {"2024-04-26", 75, 130},
    {"2024-04-27", 383, 420},
    {"2024-04-28", 122, 180},
    {"2024-04-29", 315, 240},
    {"2024-04-30", 454, 380}
  ]

  @doc false
  def chart_demo_series?(series), do: series in ~w(desktop mobile)

  defp chart_demo(assigns) do
    series =
      if(chart_demo_series?(assigns.chart_demo_series),
        do: assigns.chart_demo_series,
        else: "desktop"
      )

    assigns =
      assign(assigns,
        chart_demo_series: series,
        chart_demo_bars: chart_demo_bars(series),
        chart_demo_ticks: chart_demo_ticks(),
        chart_demo_total: chart_demo_total(series)
      )

    ~H"""
    <.card
      id="chart-demo"
      class="w-full max-w-4xl py-0 pb-4"
      data-chart-demo-series={@chart_demo_series}
    >
      <.card_header class="flex flex-col items-stretch gap-0 border-b p-0! sm:flex-row">
        <div class="flex flex-1 flex-col justify-center gap-1 px-6 pt-4 pb-3 sm:py-0!">
          <.card_title>Bar Chart - Interactive</.card_title>
          <.card_description>Showing total visitors for the last 3 months</.card_description>
        </div>
        <div class="flex">
          <button
            id="chart-demo-desktop"
            type="button"
            data-active={to_string(@chart_demo_series == "desktop")}
            class="relative z-30 flex flex-1 flex-col justify-center gap-1 border-t px-6 py-4 text-left even:border-l data-[active=true]:bg-muted/50 sm:border-t-0 sm:border-l sm:px-8 sm:py-6"
            phx-click="chart_demo_select"
            phx-value-series="desktop"
          >
            <span class="text-xs text-muted-foreground">Desktop</span>
            <span class="text-lg leading-none font-bold sm:text-3xl">7,324</span>
          </button>
          <button
            id="chart-demo-mobile"
            type="button"
            data-active={to_string(@chart_demo_series == "mobile")}
            class="relative z-30 flex flex-1 flex-col justify-center gap-1 border-t px-6 py-4 text-left even:border-l data-[active=true]:bg-muted/50 sm:border-t-0 sm:border-l sm:px-8 sm:py-6"
            phx-click="chart_demo_select"
            phx-value-series="mobile"
          >
            <span class="text-xs text-muted-foreground">Mobile</span>
            <span class="text-lg leading-none font-bold sm:text-3xl">7,250</span>
          </button>
        </div>
      </.card_header>
      <.card_content class="px-2 sm:p-6">
        <.chart_container
          id="chart-demo-bars"
          config={%{desktop: %{color: "var(--chart-2)"}, mobile: %{color: "var(--chart-1)"}}}
          class="aspect-auto h-[250px] w-full"
        >
          <div
            class="recharts-wrapper relative h-[250px] w-full"
            data-chart-demo-active={@chart_demo_series}
          >
            <svg class="recharts-surface size-full" viewBox="0 0 720 250" role="application">
              <g class="recharts-cartesian-grid">
                <line
                  :for={y <- [8, 62, 116, 170, 224]}
                  class="recharts-cartesian-grid-line"
                  x1="10"
                  x2="710"
                  y1={y}
                  y2={y}
                  stroke="#ccc"
                  fill="none"
                />
              </g>
              <g class="recharts-layer recharts-cartesian-axis recharts-xAxis xAxis">
                <text
                  :for={tick <- @chart_demo_ticks}
                  x={tick.x}
                  y="244"
                  class="recharts-text recharts-cartesian-axis-tick-value"
                  text-anchor="middle"
                  fill="#666"
                >
                  <tspan x={tick.x} dy="0.71em">{tick.label}</tspan>
                </text>
              </g>
              <g class="recharts-layer recharts-bar">
                <rect
                  :for={bar <- @chart_demo_bars}
                  data-chart-date={bar.date}
                  data-chart-series={@chart_demo_series}
                  data-chart-value={bar.value}
                  class="recharts-rectangle"
                  x={bar.x}
                  y={bar.y}
                  width={bar.width}
                  height={bar.height}
                  rx="2"
                  fill={"var(--color-#{@chart_demo_series})"}
                />
              </g>
            </svg>
            <span class="sr-only" data-chart-demo-total={@chart_demo_series}>{@chart_demo_total}</span>
          </div>
        </.chart_container>
      </.card_content>
    </.card>
    """
  end

  defp chart_demo_bars(series) do
    @chart_demo_data
    |> Enum.with_index()
    |> Enum.map(fn {{date, desktop, mobile}, index} ->
      value = if(series == "mobile", do: mobile, else: desktop)
      height = Float.round(value * 216 / 500, 4)

      %{
        date: date,
        value: value,
        x: Float.round(10 + index * (700 / 30), 4),
        y: Float.round(224 - height, 4),
        width: Float.round(700 / 30 - 3, 4),
        height: height
      }
    end)
  end

  defp chart_demo_total("mobile"), do: "7,250"
  defp chart_demo_total(_series), do: "7,324"

  defp chart_demo_ticks do
    @chart_demo_data
    |> Enum.with_index()
    |> Enum.filter(fn {_item, index} -> rem(index, 5) == 0 end)
    |> Enum.map(fn {{date, _desktop, _mobile}, index} ->
      %{
        x: Float.round(10 + index * (700 / 30) + 10, 4),
        label: "Apr #{String.slice(date, -2, 2)}"
      }
    end)
  end

  defp chart_example(assigns) do
    ~H"""
    <.chart_bar id="chart-example" />
    """
  end

  defp chart_example_grid(assigns) do
    ~H"""
    <.chart_bar id="chart-example-grid" grid />
    """
  end

  defp chart_example_axis(assigns) do
    ~H"""
    <.chart_bar id="chart-example-axis" grid axis />
    """
  end

  defp chart_example_tooltip(assigns) do
    ~H"""
    <.chart_bar id="chart-example-tooltip" grid axis tooltip />
    """
  end

  defp chart_example_legend(assigns) do
    ~H"""
    <.chart_bar id="chart-example-legend" grid axis legend tooltip />
    """
  end

  defp chart_rtl(assigns) do
    ~H"""
    <.chart_bar id="chart-rtl" grid axis legend rtl tooltip />
    """
  end

  attr(:id, :string, required: true)
  attr(:grid, :boolean, default: false)
  attr(:axis, :boolean, default: false)
  attr(:legend, :boolean, default: false)
  attr(:rtl, :boolean, default: false)
  attr(:tooltip, :boolean, default: false)

  defp chart_bar(assigns) do
    baseline = if(assigns.legend, do: 342, else: if(assigns.axis, do: 370, else: 400))

    assigns =
      assign(assigns,
        baseline: baseline,
        cursor_height: baseline - 6,
        desktop: chart_series([186, 305, 237, 73, 209, 214], :desktop, baseline, assigns.rtl),
        mobile: chart_series([80, 200, 120, 190, 130, 140], :mobile, baseline, assigns.rtl),
        ticks: chart_ticks(assigns.rtl),
        tick_y: baseline + 16
      )

    ~H"""
    <.chart_container
      id={@id}
      config={
        %{
          desktop: %{color: if(@rtl, do: "var(--chart-2)", else: "#2563eb")},
          mobile: %{color: if(@rtl, do: "var(--chart-1)", else: "#60a5fa")}
        }
      }
      class="min-h-[200px] w-full"
    >
      <div
        id={@id <> "-interaction"}
        class="recharts-wrapper relative size-full"
        phx-hook={@tooltip && "ChartTooltip"}
        data-chart-rtl={if(@rtl, do: "true", else: "false")}
      >
        <div
          :if={@tooltip}
          data-chart-tooltip
          class="recharts-tooltip-wrapper recharts-tooltip-wrapper-right recharts-tooltip-wrapper-bottom"
          style="visibility: hidden; pointer-events: none; position: absolute; top: 0px; left: 0px; transform: translate(0px, 0px);"
        >
          <.chart_tooltip_content
            label={if(@rtl, do: "يناير", else: "January")}
            label_class={@rtl && "w-32"}
          >
            <:item label={if(@rtl, do: "سطح المكتب", else: "Desktop")} color="var(--color-desktop)">
              186
            </:item>
            <:item label={if(@rtl, do: "الجوال", else: "Mobile")} color="var(--color-mobile)">
              80
            </:item>
          </.chart_tooltip_content>
        </div>
        <div
          :if={@legend}
          class="recharts-legend-wrapper"
          style="position: absolute; width: 710px; height: auto; left: 5px; bottom: 5px;"
        >
          <.chart_legend_content>
            <:item color="var(--color-desktop)">{if(@rtl, do: "سطح المكتب", else: "Desktop")}</:item>
            <:item color="var(--color-mobile)">{if(@rtl, do: "الجوال", else: "Mobile")}</:item>
          </.chart_legend_content>
        </div>
        <svg
          class="recharts-surface size-full"
          width="720"
          height="405"
          viewBox="0 0 720 405"
          role="application"
        >
          <g :if={@grid} class="recharts-cartesian-grid">
            <line
              :for={y <- chart_grid(@baseline)}
              class="recharts-cartesian-grid-line"
              x1="5"
              x2="715"
              y1={y}
              y2={y}
              stroke="#ccc"
              fill="none"
            />
          </g>
          <g :if={@axis} class="recharts-layer recharts-cartesian-axis recharts-xAxis xAxis">
            <text
              :for={tick <- @ticks}
              height="30"
              orientation="bottom"
              width="710"
              stroke="none"
              x={tick.x}
              y={@tick_y}
              class="recharts-text recharts-cartesian-axis-tick-value"
              text-anchor="middle"
              fill="#666"
            >
              <tspan x={tick.x} dy="0.71em">{tick.label}</tspan>
            </text>
          </g>
          <path
            :if={@tooltip}
            data-chart-cursor
            data-chart-cursor-height={@cursor_height}
            class="recharts-rectangle recharts-tooltip-cursor"
            fill="#ccc"
            stroke="none"
            d={"M 5,5.5 h 118.3333 v #{@cursor_height} h -118.3333 Z"}
            style="visibility: hidden;"
          />
          <g class="recharts-layer recharts-bar">
            <path
              :for={bar <- @desktop}
              data-chart-index={@tooltip && bar.index}
              data-chart-month={@tooltip && bar.month}
              data-chart-series={@tooltip && "desktop"}
              data-chart-value={@tooltip && bar.value}
              x={bar.x}
              y={bar.y}
              width="45"
              height={bar.height}
              radius="4"
              class="recharts-rectangle"
              fill="var(--color-desktop)"
              d={bar.path}
            />
          </g>
          <g class="recharts-layer recharts-bar">
            <path
              :for={bar <- @mobile}
              data-chart-index={@tooltip && bar.index}
              data-chart-month={@tooltip && bar.month}
              data-chart-series={@tooltip && "mobile"}
              data-chart-value={@tooltip && bar.value}
              x={bar.x}
              y={bar.y}
              width="45"
              height={bar.height}
              radius="4"
              class="recharts-rectangle"
              fill="var(--color-mobile)"
              d={bar.path}
            />
          </g>
        </svg>
      </div>
    </.chart_container>
    """
  end

  defp chart_series(values, series, baseline, rtl) do
    x =
      case series do
        :desktop -> [16.8333, 135.1667, 253.5, 371.8333, 490.1667, 608.5]
        :mobile -> [65.8333, 184.1667, 302.5, 420.8333, 539.1667, 657.5]
      end

    x = if(rtl, do: Enum.reverse(x), else: x)
    span = baseline - 5

    months =
      if(rtl,
        do: ~w(يناير فبراير مارس أبريل مايو يونيو),
        else: ~w(January February March April May June)
      )

    values
    |> Enum.zip(x)
    |> Enum.with_index()
    |> Enum.map(fn {{value, left}, index} ->
      height = Float.round(value * span / 320, 4)
      top = Float.round(baseline - height, 4)
      right = Float.round(left + 45, 4)
      inner_left = Float.round(left + 4, 4)
      inner_right = Float.round(right - 4, 4)
      lower = baseline - 4

      %{
        index: index,
        month: Enum.at(months, index),
        value: value,
        x: left,
        y: top,
        height: height,
        path:
          "M #{left},#{Float.round(top + 4, 4)} A 4,4,0,0,1,#{inner_left},#{top} " <>
            "L #{inner_right},#{top} A 4,4,0,0,1,#{right},#{Float.round(top + 4, 4)} " <>
            "L #{right},#{lower} A 4,4,0,0,1,#{inner_right},#{baseline} " <>
            "L #{inner_left},#{baseline} A 4,4,0,0,1,#{left},#{lower} Z"
      }
    end)
  end

  defp chart_grid(baseline) do
    span = baseline - 5
    Enum.map(0..4, &Float.round(baseline - &1 * span / 4, 4))
  end

  defp chart_ticks(false) do
    Enum.zip_with(
      [64.16666666666666, 182.5, 300.8333333333333, 419.1666666666667, 537.5, 655.8333333333333],
      ~w(Jan Feb Mar Apr May Jun),
      &%{x: &1, label: &2}
    )
  end

  defp chart_ticks(true) do
    Enum.zip_with(
      [655.8333333333333, 537.5, 419.1666666666667, 300.8333333333333, 182.5, 64.16666666666666],
      ~w(ينا فبر مار أبر ماي يون),
      &%{x: &1, label: &2}
    )
  end

  defp chart_tooltip(assigns) do
    ~H"""
    <div class="grid aspect-video w-full max-w-md justify-center text-foreground md:grid-cols-2 [&>div]:relative [&>div]:flex [&>div]:h-[137px] [&>div]:w-[224px] [&>div]:items-center [&>div]:justify-center [&>div]:p-4">
      <div>
        <div class="absolute top-[45px] left-[-35px] z-10 text-sm font-medium">Label</div>
        <svg
          viewBox="0 0 193 40"
          width="50"
          height="12"
          fill="none"
          class="absolute top-[50px] left-[5px] z-10"
        >
          <path
            fill="currentColor"
            d="M173.928 21.13C115.811 44.938 58.751 45.773 0 26.141c4.227-4.386 7.82-2.715 10.567-1.88 21.133 5.64 42.9 6.266 64.457 7.101 31.066 1.253 60.441-5.848 89.183-17.335 1.268-.418 2.325-1.253 4.861-2.924-14.582-2.924-29.165 2.089-41.845-3.76.212-.835.212-1.879.423-2.714 9.51-.627 19.231-1.253 28.742-2.089 9.51-.835 18.808-1.88 28.318-2.506 6.974-.418 9.933 2.924 7.397 9.19-3.17 8.145-7.608 15.664-11.623 23.391-.423.836-1.057 1.88-1.902 2.298-2.325.835-4.65 1.044-7.186 1.67-.422-2.088-1.479-4.386-1.268-6.265.423-2.506 1.902-4.595 3.804-9.19Z"
          />
        </svg>
        <.chart_tooltip_demo_content
          label="Page Views"
          class="w-[8rem]"
        >
          <:item label="Desktop" color="var(--chart-1)">186</:item>
          <:item label="Mobile" color="var(--chart-2)">80</:item>
        </.chart_tooltip_demo_content>
      </div>
      <div class="items-end">
        <div class="absolute top-[0px] left-[122px] z-10 text-sm font-medium">Name</div>
        <svg
          width="35"
          height="42"
          fill="none"
          viewBox="0 0 122 148"
          class="absolute top-[10px] left-[85px] z-10 -scale-x-100"
        >
          <path
            fill="currentColor"
            d="M0 2.65c6.15-4.024 12.299-2.753 17.812-.847a115.56 115.56 0 0 1 21.84 10.59C70.4 32.727 88.849 61.744 96.483 97.54c1.908 9.108 2.544 18.639 3.817 29.017 8.481-4.871 12.934-14.402 21.416-19.909 1.061 4.236-1.06 6.989-2.756 9.319-6.998 9.531-14.207 19.062-21.63 28.382-3.604 4.448-6.36 4.871-10.177 1.059-8.058-7.837-12.935-17.368-14.42-28.382 0-.424.636-1.059 1.485-2.118 9.118 2.33 6.997 13.979 14.843 18.215 3.393-14.614.848-28.593-2.969-42.149-4.029-14.19-9.33-27.746-17.812-39.82-8.27-11.86-18.66-21.392-30.11-30.287C26.93 11.758 14.207 6.039 0 2.65Z"
          />
        </svg>
        <.chart_tooltip_demo_content
          hide_label
          indicator="dashed"
          class="w-[8rem]"
        >
          <:item label="Chrome" color="var(--chart-3)">1,286</:item>
          <:item label="Firefox" color="var(--chart-4)">1,000</:item>
        </.chart_tooltip_demo_content>
      </div>
      <div class="hidden! md:flex!">
        <.chart_tooltip_demo_content
          label="Page Views"
          indicator="line"
          class="w-[9rem]"
        >
          <:item label="Desktop" color="var(--chart-3)">12,486</:item>
        </.chart_tooltip_demo_content>
      </div>
      <div class="items-start! justify-start!">
        <div class="absolute top-[60px] left-[50px] z-10 text-sm font-medium">Indicator</div>
        <.chart_tooltip_demo_content
          hide_label
          class="w-[8rem]"
        >
          <:item label="Chrome" color="var(--chart-1)">1,286</:item>
        </.chart_tooltip_demo_content>
        <svg
          width="15"
          height="34"
          fill="none"
          viewBox="0 0 75 175"
          class="absolute top-[38px] left-[30px] z-10 rotate-[-40deg]"
        >
          <path
            fill="currentColor"
            d="M20.187 175c-4.439-2.109-7.186-2.531-8.032-4.008-3.17-5.484-6.763-10.968-8.454-17.084-5.073-16.242-4.439-32.694-1.057-49.146 5.707-28.053 18.388-52.942 34.24-76.565 1.692-2.531 3.171-5.063 4.862-7.805 0-.21-.211-.632-.634-1.265-4.65 1.265-9.511 2.53-14.161 3.585-2.537.422-5.496.422-8.032-.421-1.48-.422-3.593-2.742-3.593-4.219 0-1.898 1.48-4.218 2.747-5.906 1.057-1.054 2.96-1.265 4.65-1.687C35.406 7.315 48.088 3.729 60.98.776c10.99-2.53 14.584 1.055 13.95 11.812-.634 11.18-.846 22.358-1.268 33.326-.212 3.375-.846 6.96-1.268 10.757-8.878-4.007-8.878-4.007-12.048-38.177C47.03 33.259 38.153 49.289 29.91 65.741 21.667 82.193 16.17 99.49 13.212 117.84c-2.959 18.984.634 36.912 6.975 57.161Z"
          />
        </svg>
      </div>
    </div>
    """
  end

  attr(:label, :string, default: nil)
  attr(:indicator, :string, default: "dot", values: ["dot", "line", "dashed"])
  attr(:hide_label, :boolean, default: false)
  attr(:hide_indicator, :boolean, default: false)
  attr(:class, :any, default: nil)

  slot(:item) do
    attr(:label, :string)
    attr(:color, :string)
  end

  defp chart_tooltip_demo_content(assigns) do
    assigns =
      assign(assigns, :nest_label, match?([_], assigns.item) and assigns.indicator != "dot")

    ~H"""
    <div class={[
      "grid min-w-[8rem] items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl transition-all ease-in-out hover:-translate-y-0.5",
      @class
    ]}>
      <div :if={@label && !@hide_label && !@nest_label} class="font-medium">{@label}</div>
      <div class="grid gap-1.5">
        <div
          :for={item <- @item}
          class={
            LiveShadcn.Cn.merge([
              "flex w-full items-stretch gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5 [&>svg]:text-muted-foreground",
              @indicator == "dot" && "items-center"
            ])
          }
        >
          <div
            :if={!@hide_indicator}
            class={
              LiveShadcn.Cn.merge([
                "shrink-0 rounded-[2px] border-(--color-border) bg-(--color-bg)",
                @indicator == "dot" && "h-2.5 w-2.5",
                @indicator == "line" && "w-1",
                @indicator == "dashed" && "w-0 border-[1.5px] border-dashed bg-transparent",
                @nest_label && @indicator == "dashed" && "my-0.5"
              ])
            }
            style={"--color-bg: #{item[:color]}; --color-border: #{item[:color]};"}
          />
          <div class={
            LiveShadcn.Cn.merge([
              "flex flex-1 justify-between leading-none",
              if(@nest_label, do: "items-end", else: "items-center")
            ])
          }>
            <div class="grid gap-1.5">
              <div :if={@label && !@hide_label && @nest_label} class="font-medium">{@label}</div>
              <span class="text-muted-foreground">{item[:label]}</span>
            </div>
            <span class="font-mono font-medium text-foreground tabular-nums">
              {render_slot(item)}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp command_default(assigns) do
    ~H"""
    <.command id="command-default" class="max-w-sm rounded-lg border">
      <.command_input
        placeholder="Type a command or search..."
        aria-label="Type a command or search"
        controls="command-default-list"
      />
      <.command_list id="command-default-list">
        <.command_empty>No results found.</.command_empty>
        <.command_group heading="Suggestions">
          <.command_item>
            <LiveShadcn.Icon.icon name="calendar" />
            <span>Calendar</span>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="smile" />
            <span>Search Emoji</span>
          </.command_item>
          <.command_item disabled>
            <LiveShadcn.Icon.icon name="calculator" />
            <span>Calculator</span>
          </.command_item>
        </.command_group>
        <.command_separator />
        <.command_group heading="Settings">
          <.command_item>
            <LiveShadcn.Icon.icon name="user" />
            <span>Profile</span>
            <.command_shortcut>⌘P</.command_shortcut>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="credit-card" />
            <span>Billing</span>
            <.command_shortcut>⌘B</.command_shortcut>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="settings" />
            <span>Settings</span>
            <.command_shortcut>⌘S</.command_shortcut>
          </.command_item>
        </.command_group>
      </.command_list>
    </.command>
    """
  end

  defp command_basic(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.button
        variant="outline"
        class="w-fit"
        phx-click={LiveBase.Dialog.open("command-basic-dialog")}
      >
        Open Menu
      </.button>
      <.command_dialog id="command-basic-dialog">
        <.command id="command-basic">
          <.command_input placeholder="Type a command or search..." />
          <.command_list>
            <.command_empty>No results found.</.command_empty>
            <.command_group heading="Suggestions">
              <.command_item>Calendar</.command_item>
              <.command_item>Search Emoji</.command_item>
              <.command_item>Calculator</.command_item>
            </.command_group>
          </.command_list>
        </.command>
      </.command_dialog>
    </div>
    """
  end

  defp command_shortcuts(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.button
        variant="outline"
        class="w-fit"
        phx-click={LiveBase.Dialog.open("command-shortcuts-dialog")}
      >
        Open Menu
      </.button>
      <.command_dialog id="command-shortcuts-dialog">
        <.command id="command-shortcuts">
          <.command_input placeholder="Type a command or search..." />
          <.command_list>
            <.command_empty>No results found.</.command_empty>
            <.command_group heading="Settings">
              <.command_item>
                <LiveShadcn.Icon.icon name="user" />
                <span>Profile</span>
                <.command_shortcut>⌘P</.command_shortcut>
              </.command_item>
              <.command_item>
                <LiveShadcn.Icon.icon name="credit-card" />
                <span>Billing</span>
                <.command_shortcut>⌘B</.command_shortcut>
              </.command_item>
              <.command_item>
                <LiveShadcn.Icon.icon name="settings" />
                <span>Settings</span>
                <.command_shortcut>⌘S</.command_shortcut>
              </.command_item>
            </.command_group>
          </.command_list>
        </.command>
      </.command_dialog>
    </div>
    """
  end

  defp command_groups(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.button
        variant="outline"
        class="w-fit"
        phx-click={LiveBase.Dialog.open("command-groups-dialog")}
      >
        Open Menu
      </.button>
      <.command_dialog id="command-groups-dialog">
        <.command id="command-groups">
          <.command_input placeholder="Type a command or search..." />
          <.command_list>
            <.command_empty>No results found.</.command_empty>
            <.command_group heading="Suggestions">
              <.command_item>
                <LiveShadcn.Icon.icon name="calendar" />
                <span>Calendar</span>
              </.command_item>
              <.command_item>
                <LiveShadcn.Icon.icon name="smile" />
                <span>Search Emoji</span>
              </.command_item>
              <.command_item>
                <LiveShadcn.Icon.icon name="calculator" />
                <span>Calculator</span>
              </.command_item>
            </.command_group>
            <.command_separator />
            <.command_settings_group />
          </.command_list>
        </.command>
      </.command_dialog>
    </div>
    """
  end

  defp command_scrollable(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.button
        variant="outline"
        class="w-fit"
        phx-click={LiveBase.Dialog.open("command-scrollable-dialog")}
      >
        Open Menu
      </.button>
      <.command_dialog id="command-scrollable-dialog">
        <.command id="command-scrollable">
          <.command_input placeholder="Type a command or search..." />
          <.command_list>
            <.command_empty>No results found.</.command_empty>
            <.command_group heading="Navigation">
              <.command_entry icon="house" label="Home" shortcut="⌘H" />
              <.command_entry icon="inbox" label="Inbox" shortcut="⌘I" />
              <.command_entry icon="file-text" label="Documents" shortcut="⌘D" />
              <.command_entry icon="folder" label="Folders" shortcut="⌘F" />
            </.command_group>
            <.command_separator />
            <.command_group heading="Actions">
              <.command_entry icon="plus" label="New File" shortcut="⌘N" />
              <.command_entry icon="folder-plus" label="New Folder" shortcut="⇧⌘N" />
              <.command_entry icon="copy" label="Copy" shortcut="⌘C" />
              <.command_entry icon="scissors" label="Cut" shortcut="⌘X" />
              <.command_entry icon="clipboard-paste" label="Paste" shortcut="⌘V" />
              <.command_entry icon="trash" label="Delete" shortcut="⌫" />
            </.command_group>
            <.command_separator />
            <.command_group heading="View">
              <.command_entry icon="layout-grid" label="Grid View" />
              <.command_entry icon="list" label="List View" />
              <.command_entry icon="zoom-in" label="Zoom In" shortcut="⌘+" />
              <.command_entry icon="zoom-out" label="Zoom Out" shortcut="⌘-" />
            </.command_group>
            <.command_separator />
            <.command_group heading="Account">
              <.command_entry icon="user" label="Profile" shortcut="⌘P" />
              <.command_entry icon="credit-card" label="Billing" shortcut="⌘B" />
              <.command_entry icon="settings" label="Settings" shortcut="⌘S" />
              <.command_entry icon="bell" label="Notifications" />
              <.command_entry icon="circle-help" label="Help & Support" />
            </.command_group>
            <.command_separator />
            <.command_group heading="Tools">
              <.command_entry icon="calculator" label="Calculator" />
              <.command_entry icon="calendar" label="Calendar" />
              <.command_entry icon="image" label="Image Editor" />
              <.command_entry icon="code" label="Code Editor" />
            </.command_group>
          </.command_list>
        </.command>
      </.command_dialog>
    </div>
    """
  end

  defp command_rtl(assigns) do
    ~H"""
    <.command id="command-rtl" class="max-w-sm rounded-lg border" dir="rtl" data-lang="ar">
      <.command_input placeholder="اكتب أمرًا أو ابحث..." dir="rtl" />
      <.command_list>
        <.command_empty>لم يتم العثور على نتائج.</.command_empty>
        <.command_group heading="اقتراحات">
          <.command_item>
            <LiveShadcn.Icon.icon name="calendar" />
            <span>التقويم</span>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="smile" />
            <span>البحث عن الرموز التعبيرية</span>
          </.command_item>
          <.command_item disabled>
            <LiveShadcn.Icon.icon name="calculator" />
            <span>الآلة الحاسبة</span>
          </.command_item>
        </.command_group>
        <.command_separator />
        <.command_group heading="الإعدادات">
          <.command_item>
            <LiveShadcn.Icon.icon name="user" />
            <span>الملف الشخصي</span>
            <.command_shortcut>⌘P</.command_shortcut>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="credit-card" />
            <span>الفوترة</span>
            <.command_shortcut>⌘B</.command_shortcut>
          </.command_item>
          <.command_item>
            <LiveShadcn.Icon.icon name="settings" />
            <span>الإعدادات</span>
            <.command_shortcut>⌘S</.command_shortcut>
          </.command_item>
        </.command_group>
      </.command_list>
    </.command>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:shortcut, :string, default: nil)

  defp command_entry(assigns) do
    ~H"""
    <.command_item>
      <LiveShadcn.Icon.icon name={@icon} />
      <span>{@label}</span>
      <.command_shortcut :if={@shortcut}>{@shortcut}</.command_shortcut>
    </.command_item>
    """
  end

  defp command_settings_group(assigns) do
    ~H"""
    <.command_group heading="Settings">
      <.command_entry icon="user" label="Profile" shortcut="⌘P" />
      <.command_entry icon="credit-card" label="Billing" shortcut="⌘B" />
      <.command_entry icon="settings" label="Settings" shortcut="⌘S" />
    </.command_group>
    """
  end

  defp input_otp_default(assigns) do
    ~H"""
    <.input_otp maxlength={6} value="123456">
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..5} index={index} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_pattern(assigns) do
    ~H"""
    <.field class="w-fit">
      <.field_label for="digits-only">Digits Only</.field_label>
      <.input_otp id="digits-only" maxlength={6} pattern={~S(^\d+$)}>
        <.input_otp_group>
          <.input_otp_slot :for={index <- 0..5} index={index} />
        </.input_otp_group>
      </.input_otp>
    </.field>
    """
  end

  defp input_otp_separator_example(assigns) do
    ~H"""
    <.input_otp maxlength={6}>
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..1} index={index} />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 2..3} index={index} />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 4..5} index={index} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_disabled(assigns) do
    ~H"""
    <.input_otp id="disabled" maxlength={6} disabled value="123456">
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..2} index={index} />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 3..5} index={index} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_controlled(assigns) do
    ~H"""
    <div class="space-y-2">
      <.input_otp
        maxlength={6}
        data-lb-input-otp-output="#input-otp-controlled-value"
        data-lb-input-otp-empty="Enter your one-time password."
        data-lb-input-otp-prefix="You entered: "
      >
        <.input_otp_group>
          <.input_otp_slot :for={index <- 0..5} index={index} />
        </.input_otp_group>
      </.input_otp>
      <div id="input-otp-controlled-value" class="text-center text-sm">
        Enter your one-time password.
      </div>
    </div>
    """
  end

  defp input_otp_invalid(assigns) do
    ~H"""
    <.input_otp maxlength={6} value="000000">
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..1} index={index} aria-invalid="true" />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 2..3} index={index} aria-invalid="true" />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 4..5} index={index} aria-invalid="true" />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_four_digits(assigns) do
    ~H"""
    <.input_otp maxlength={4} pattern={~S(^\d+$)}>
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..3} index={index} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_alphanumeric(assigns) do
    ~H"""
    <.input_otp maxlength={6} pattern={~S(^[a-zA-Z0-9]+$)}>
      <.input_otp_group>
        <.input_otp_slot :for={index <- 0..2} index={index} />
      </.input_otp_group>
      <.input_otp_separator />
      <.input_otp_group>
        <.input_otp_slot :for={index <- 3..5} index={index} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  defp input_otp_form(assigns) do
    ~H"""
    <.card class="mx-auto max-w-md">
      <.card_header>
        <.card_title>Verify your login</.card_title>
        <.card_description>
          Enter the verification code we sent to your email address:{" "}
          <span class="font-medium">m@example.com</span>.
        </.card_description>
      </.card_header>
      <.card_content>
        <.field>
          <div class="flex items-center justify-between">
            <.field_label for="otp-verification">Verification code</.field_label>
            <.button variant="outline" size="xs">
              <LiveShadcn.Icon.icon name="refresh-cw" />Resend Code
            </.button>
          </div>
          <.input_otp id="otp-verification" maxlength={6} required>
            <.input_otp_group class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl">
              <.input_otp_slot :for={index <- 0..2} index={index} />
            </.input_otp_group>
            <.input_otp_separator class="mx-2" />
            <.input_otp_group class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl">
              <.input_otp_slot :for={index <- 3..5} index={index} />
            </.input_otp_group>
          </.input_otp>
          <.field_description>
            <a href="#">I no longer have access to this email address.</a>
          </.field_description>
        </.field>
      </.card_content>
      <.card_footer>
        <.field>
          <.button type="submit" class="w-full">Verify</.button>
          <div class="text-sm text-muted-foreground">
            Having trouble signing in?{" "}
            <a href="#" class="underline underline-offset-4 transition-colors hover:text-primary">
              Contact support
            </a>
          </div>
        </.field>
      </.card_footer>
    </.card>
    """
  end

  defp input_otp_rtl(assigns) do
    ~H"""
    <.field class="mx-auto max-w-xs">
      <.field_label for="input-otp-rtl">رمز التحقق</.field_label>
      <.input_otp id="input-otp-rtl" maxlength={6} value="123456" dir="rtl">
        <.input_otp_group>
          <.input_otp_slot :for={index <- 0..5} index={index} />
        </.input_otp_group>
      </.input_otp>
    </.field>
    """
  end

  defp message_scroller_default(assigns) do
    messages = @message_scroller_chat |> Enum.take(length(assigns.message_scroller.default))
    busy = assigns.message_scroller.default_busy
    next_message = next_chat_user(messages)
    assigns = assign(assigns, messages: messages, busy: busy, next_message: next_message)

    ~H"""
    <.message_scroller_provider>
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>New Chat</.card_title><.card_description>
              How can I help you today?
            </.card_description><.card_action>
              <.tooltip
                id="message-scroller-default-reset-tooltip"
                trigger_label="Reset conversation"
                trigger_size="icon"
                disabled={@busy}
                hover_expanded={false}
                trigger_click={
                  Phoenix.LiveView.JS.push("message_scroller_reset", value: %{example: "default"})
                }
              >
                <:trigger><LiveShadcn.Icon.icon name="rotate-cw" /></:trigger>
                Reset
              </.tooltip>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.empty :if={@messages == []} class="h-full">
              <.empty_header>
                <.empty_media variant="icon">
                  <LiveShadcn.Icon.icon name="message-circle-dashed" />
                </.empty_media><.empty_title>Morning, shadcn!</.empty_title><.empty_description>
                  What are we working on today? Press send to start a new conversation
                </.empty_description>
              </.empty_header>
            </.empty>
            <.message_scroller :if={@messages != []} id="message-scroller-default">
              <.message_scroller_viewport
                id="message-scroller-default-viewport"
                controller="message-scroller-default"
              >
                <.message_scroller_content aria-busy={to_string(@busy)} class="p-(--card-spacing)">
                  <.message_scroller_rows messages={@messages} animation_preset="slide-up" />
                </.message_scroller_content>
              </.message_scroller_viewport><.message_scroller_button />
            </.message_scroller>
          </.card_content>
          <.card_footer class="flex-col gap-2">
            <form
              id="message-scroller-default-form"
              class="w-full"
              phx-submit="message_scroller_send"
              phx-value-example="default"
            >
              <.input_group>
                <div class="h-14 w-full px-3 py-2.5">
                  <span
                    class="line-clamp-2 opacity-60 data-[status=ready]:opacity-100"
                    data-status={if(@busy, do: "streaming", else: "ready")}
                  >
                    <%= if @next_message do %>
                      {@next_message.text}
                    <% else %>
                      <span class="text-muted-foreground">No messages queued. Reset the conversation.</span>
                    <% end %>
                  </span>
                </div>
                <.input_group_addon align="block-end" class="pt-1">
                  <.dropdown_menu
                    id="message-scroller-default-add-files"
                    direct_trigger
                    transient_controls
                    side="top"
                    align="start"
                    class="w-44"
                    trigger_variant="outline"
                    trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-sm"
                    trigger_attrs={%{"aria-label" => "Add files"}}
                  >
                    <:trigger><LiveShadcn.Icon.icon name="plus" /></:trigger>
                    <:entry kind="item" value="add-photos">
                      <LiveShadcn.Icon.icon name="paperclip" /> Add Photos & Files
                    </:entry>
                    <:entry kind="separator" />
                    <:entry kind="item" value="create-image">
                      <LiveShadcn.Icon.icon name="image" /> Create Image
                    </:entry>
                    <:entry kind="item" value="deep-research">
                      <LiveShadcn.Icon.icon name="telescope" /> Deep Research
                    </:entry>
                    <:entry kind="item" value="web-search">
                      <LiveShadcn.Icon.icon name="globe" /> Web Search
                    </:entry>
                  </.dropdown_menu>
                  <.input_group_button
                    type="submit"
                    variant="default"
                    size="icon-sm"
                    disabled={is_nil(@next_message) || @busy}
                    class="ml-auto"
                  ><LiveShadcn.Icon.icon name="arrow-up" /><span class="sr-only">Send</span></.input_group_button>
                </.input_group_addon>
              </.input_group>
            </form>
          </.card_footer>
        </.card>
        <div class="px-0.5 text-center text-xs text-muted-foreground">
          Demo is read only. Press send to send messages.
        </div>
      </div>
    </.message_scroller_provider>
    """
  end

  defp message_scroller_anchoring(assigns) do
    messages = @message_scroller_anchoring |> Enum.take(assigns.message_scroller.anchoring_index)

    assigns =
      assign(assigns, messages: messages, anchoring_count: length(@message_scroller_anchoring))

    ~H"""
    <div class="relative flex flex-col gap-4">
      <.card class="mx-auto h-140 w-full max-w-sm gap-0">
        <.card_header class="border-b">
          <.card_title>Anchoring Turns</.card_title><.card_description>
            Choose which role settles near the top edge.
          </.card_description><.card_action>
            <.button
              type="button"
              variant="outline"
              size="icon"
              aria-label="Reset anchored turns"
              disabled={@messages == []}
              phx-click="message_scroller_reset"
              phx-value-example="anchoring"
            ><LiveShadcn.Icon.icon name="rotate-cw" /></.button>
          </.card_action>
        </.card_header><.card_content class="min-h-0 flex-1 overflow-hidden p-0">
          <.empty :if={@messages == []} class="h-full">
            <.empty_header>
              <.empty_media variant="icon">
                <LiveShadcn.Icon.icon name="message-circle-dashed" />
              </.empty_media><.empty_title>No anchored messages yet</.empty_title><.empty_description>
                Send the first message to see the selected role anchor.
              </.empty_description>
            </.empty_header>
          </.empty><.message_scroller_provider :if={@messages != []}>
            <.message_scroller id="message-scroller-anchoring">
              <.message_scroller_viewport
                id="message-scroller-anchoring-viewport"
                controller="message-scroller-anchoring"
              >
                <.message_scroller_content class="p-(--card-spacing)">
                  <.message_scroller_rows
                    messages={@messages}
                    anchor_role={@message_scroller.anchoring_role}
                    animation_preset="slide-up"
                  />
                </.message_scroller_content>
              </.message_scroller_viewport><.message_scroller_button />
            </.message_scroller>
          </.message_scroller_provider>
        </.card_content><.card_footer>
          <.toggle_group id="message-scroller-anchor-role" aria-label="Select scroll anchor role">
            <:item
              id="message-scroller-anchor-role-user"
              value="user"
              native_value=""
              checked={@message_scroller.anchoring_role == :user}
              aria-label="Anchor user messages"
              on_click={
                %Phoenix.LiveView.JS{}
                |> Phoenix.LiveView.JS.push("message_scroller_anchor_role", value: %{role: "user"})
              }
            >
              User
            </:item><:item
              id="message-scroller-anchor-role-assistant"
              value="assistant"
              native_value=""
              checked={@message_scroller.anchoring_role == :assistant}
              aria-label="Anchor assistant messages"
              on_click={
                %Phoenix.LiveView.JS{}
                |> Phoenix.LiveView.JS.push("message_scroller_anchor_role",
                  value: %{role: "assistant"}
                )
              }
            >
              Assistant
            </:item>
          </.toggle_group><.button
            type="button"
            size="icon"
            class="ml-auto"
            aria-label="Send Message"
            disabled={@message_scroller.anchoring_index >= @anchoring_count}
            phx-click="message_scroller_send"
            phx-value-example="anchoring"
          ><LiveShadcn.Icon.icon name="arrow-up" /><span class="sr-only">Send Message</span></.button>
        </.card_footer>
      </.card><div class="mx-auto max-w-xs px-0.5 text-center text-xs text-muted-foreground">
        Toggle the anchor role, then send messages to compare where turns settle.
      </div>
    </div>
    """
  end

  defp message_scroller_group_chat(assigns) do
    items = [
      %{
        id: "group-1",
        sender: "Grace",
        role: :participant,
        text:
          "@mary, the astrophage line keeps matching Venus energy output. Can you check my math?",
        scroll_anchor: false
      },
      %{
        id: "group-2",
        sender: "Mary (Agent)",
        role: :assistant,
        text:
          "Yes. Confirmed. The curve points to a microorganism harvesting stellar energy and breeding near carbon dioxide. If @rocky agrees, this is the clue we need.",
        scroll_anchor: false
      },
      %{
        id: "group-3",
        sender: "Grace",
        role: :participant,
        text: "ping @rocky",
        scroll_anchor: true
      }
    ]

    assigns =
      assign(assigns,
        items: items,
        generation: assigns.message_scroller.group_generation,
        opening_position:
          if(assigns.message_scroller.group_generation == 0, do: "end", else: "start")
      )

    ~H"""
    <.message_scroller_provider>
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Group Chat</.card_title><.card_description>
              A group chat with several participants and an assistant. The Marker is marked as a turn.
            </.card_description><.card_action>
              <.tooltip
                id="message-scroller-group-chat-reset-tooltip"
                trigger_label="Reset conversation"
                trigger_size="icon"
                disabled={@message_scroller.group_turn == :idle}
                trigger_click={
                  Phoenix.LiveView.JS.push("message_scroller_reset", value: %{example: "group-chat"})
                }
              >
                <:trigger><LiveShadcn.Icon.icon name="rotate-cw" /></:trigger>
                Reset
              </.tooltip>
            </.card_action>
          </.card_header><.card_content class="min-h-0 flex-1 p-0">
            <.message_scroller
              id={"message-scroller-group-chat-#{@generation}"}
              default_scroll_position={@opening_position}
            >
              <.message_scroller_viewport
                id={"message-scroller-group-chat-viewport-#{@generation}"}
                controller={"message-scroller-group-chat-#{@generation}"}
                default_scroll_position={@opening_position}
              >
                <.message_scroller_content class="p-(--card-spacing)">
                  <.group_chat_rows items={@items} turn={@message_scroller.group_turn} />
                </.message_scroller_content>
              </.message_scroller_viewport><.message_scroller_button />
            </.message_scroller>
          </.card_content><.card_footer class="flex flex-col items-center gap-2 border-t">
            <.button
              type="button"
              disabled={@message_scroller.group_turn == :message}
              class="w-full"
              variant="secondary"
              phx-click="message_scroller_group_next"
            >{if @message_scroller.group_turn == :idle, do: "Add Rocky", else: "Send Message as Rocky"}</.button><p class="text-xs text-muted-foreground">
              {if @message_scroller.group_turn == :idle,
                do: "This will create a marker and make it the anchor",
                else: "Now send Rocky's reply into the conversation"}
            </p>
          </.card_footer>
        </.card><div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
          When a user joins, a marker is created. scrollAnchor on the marker marks it as the next turn
        </div>
      </div>
    </.message_scroller_provider>
    """
  end

  defp message_scroller_previous_context(assigns) do
    messages =
      Enum.take(@message_scroller_chat, length(assigns.message_scroller.previous_context))

    busy = assigns.message_scroller.previous_context_busy
    next_message = next_chat_user(messages)

    assigns =
      assign(assigns,
        messages: messages,
        busy: busy,
        next_message: next_message,
        peek: assigns.message_scroller.previous_context_peek,
        generation: assigns.message_scroller.previous_context_generation
      )

    ~H"""
    <.message_scroller_provider :let={config} scroll_margin={24} scroll_previous_item_peek={@peek}>
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Keeping Context Visible</.card_title>
            <.card_description>New turns keep part of the previous reply in view.</.card_description>
            <.card_action>
              <.tooltip
                id="message-scroller-previous-context-reset-tooltip"
                trigger_label="Reset context example"
                trigger_size="icon"
                disabled={@busy}
                hover_expanded={false}
                trigger_click={
                  Phoenix.LiveView.JS.push("message_scroller_reset",
                    value: %{example: "previous-context"}
                  )
                }
              >
                <:trigger><LiveShadcn.Icon.icon name="rotate-cw" /></:trigger>
                Reset
              </.tooltip>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller
              id="message-scroller-previous-context"
              scroll_margin={config.scroll_margin}
              scroll_previous_item_peek={config.scroll_previous_item_peek}
              data-lb-message-opening-generation={@generation}
              data-lb-message-opening-hold="false"
            >
              <.message_scroller_viewport
                id="message-scroller-previous-context-viewport"
                controller="message-scroller-previous-context"
              >
                <.message_scroller_content
                  id={"message-scroller-previous-context-content-#{@generation}"}
                  aria-busy={to_string(@busy)}
                  class="p-(--card-spacing)"
                >
                  <.message_scroller_rows
                    messages={@messages}
                    anchor_role={:user}
                    animation_preset="slide-up"
                  />
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
          <.card_footer class="flex-col gap-2">
            <form
              id="message-scroller-previous-context-form"
              class="w-full"
              phx-submit="message_scroller_send"
              phx-value-example="previous-context"
            >
              <.input_group>
                <div class="h-14 w-full px-3 py-2.5">
                  <span
                    class="line-clamp-2 opacity-60 data-[status=ready]:opacity-100"
                    data-status={if(@busy, do: "streaming", else: "ready")}
                  >
                    <%= if @next_message do %>
                      {@next_message.text}
                    <% else %>
                      <span class="text-muted-foreground">No messages queued. Reset the context.</span>
                    <% end %>
                  </span>
                </div>
                <.input_group_addon align="block-end" class="pt-1">
                  <.dropdown_menu
                    id="message-scroller-previous-context-add-files"
                    direct_trigger
                    transient_controls
                    side="top"
                    align="start"
                    class="w-44"
                    trigger_variant="outline"
                    trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-sm"
                    trigger_attrs={%{"aria-label" => "Add files"}}
                  >
                    <:trigger><LiveShadcn.Icon.icon name="plus" /></:trigger>
                    <:entry kind="item" value="add-photos">
                      <LiveShadcn.Icon.icon name="paperclip" /> Add Photos & Files
                    </:entry>
                    <:entry kind="separator" />
                    <:entry kind="item" value="create-image">
                      <LiveShadcn.Icon.icon name="image" /> Create Image
                    </:entry>
                    <:entry kind="item" value="deep-research">
                      <LiveShadcn.Icon.icon name="telescope" /> Deep Research
                    </:entry>
                    <:entry kind="item" value="web-search">
                      <LiveShadcn.Icon.icon name="globe" /> Web Search
                    </:entry>
                  </.dropdown_menu>
                  <div class="flex w-28 items-center gap-2">
                    <span class="text-xs text-muted-foreground tabular-nums">{@peek}px</span>
                    <.slider
                      id="message-scroller-previous-context-peek"
                      name="peek"
                      value={@peek}
                      min={64}
                      max={128}
                      step={1}
                      label="Previous context peek"
                      disabled={@busy}
                      on_change="message_scroller_peek"
                    />
                  </div>
                  <.input_group_button
                    type="submit"
                    variant="default"
                    size="icon-sm"
                    disabled={is_nil(@next_message) || @busy}
                    class="ml-auto"
                  ><LiveShadcn.Icon.icon name="arrow-up" /><span class="sr-only">Send</span></.input_group_button>
                </.input_group_addon>
              </.input_group>
            </form>
          </.card_footer>
        </.card>
        <div class="px-0.5 text-center text-xs text-muted-foreground">
          Adjust the slider and send. Observe the previous message peak
        </div>
      </div>
    </.message_scroller_provider>
    """
  end

  defp message_scroller_streaming(assigns) do
    messages = Enum.take(@message_scroller_chat, length(assigns.message_scroller.streaming))
    busy = assigns.message_scroller.streaming_busy
    next_message = next_chat_user(messages)
    assigns = assign(assigns, messages: messages, busy: busy, next_message: next_message)

    ~H"""
    <.message_scroller_provider auto_scroll>
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Streaming Messages</.card_title>
            <.card_description>
              Auto-scroll follows the live edge of the conversation.
            </.card_description>
            <.card_action>
              <.tooltip
                id="message-scroller-streaming-reset-tooltip"
                trigger_label="Reset stream"
                trigger_size="icon"
                disabled={@messages == [] || @busy}
                hover_expanded={false}
                trigger_click={
                  Phoenix.LiveView.JS.push("message_scroller_reset", value: %{example: "streaming"})
                }
              >
                <:trigger><LiveShadcn.Icon.icon name="rotate-cw" /></:trigger>
                Reset
              </.tooltip>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.empty :if={@messages == []} class="h-full">
              <.empty_header>
                <.empty_media variant="icon">
                  <LiveShadcn.Icon.icon name="message-circle-dashed" />
                </.empty_media>
                <.empty_title>Ready to Stream</.empty_title>
                <.empty_description>
                  Press send to stream a scripted launch summary.
                </.empty_description>
              </.empty_header>
            </.empty>
            <.message_scroller :if={@messages != []} id="message-scroller-streaming" auto_scroll>
              <.message_scroller_viewport
                id="message-scroller-streaming-viewport"
                controller="message-scroller-streaming"
              >
                <.message_scroller_content aria-busy={to_string(@busy)} class="p-(--card-spacing)">
                  <.message_scroller_rows
                    messages={@messages}
                    animation_preset="slide-up"
                  />
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
          <.card_footer class="flex-col gap-2">
            <form class="w-full" phx-submit="message_scroller_send" phx-value-example="streaming">
              <.input_group>
                <div class="h-14 w-full px-3 py-2.5">
                  <span
                    class="line-clamp-2 opacity-60 data-[status=ready]:opacity-100"
                    data-status={if(@busy, do: "streaming", else: "ready")}
                  >
                    <%= if @next_message do %>
                      {@next_message.text}
                    <% else %>
                      <span class="text-muted-foreground">No messages queued. Reset the stream.</span>
                    <% end %>
                  </span>
                </div>
                <.input_group_addon align="block-end" class="pt-1">
                  <.dropdown_menu
                    id="message-scroller-streaming-add-files"
                    direct_trigger
                    transient_controls
                    side="top"
                    align="start"
                    class="w-44"
                    trigger_variant="outline"
                    trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-sm"
                    trigger_attrs={%{"aria-label" => "Add files"}}
                  >
                    <:trigger><LiveShadcn.Icon.icon name="plus" /></:trigger>
                    <:entry kind="item" value="add-photos">
                      <LiveShadcn.Icon.icon name="paperclip" /> Add Photos & Files
                    </:entry>
                    <:entry kind="separator" />
                    <:entry kind="item" value="create-image">
                      <LiveShadcn.Icon.icon name="image" /> Create Image
                    </:entry>
                    <:entry kind="item" value="deep-research">
                      <LiveShadcn.Icon.icon name="telescope" /> Deep Research
                    </:entry>
                    <:entry kind="item" value="web-search">
                      <LiveShadcn.Icon.icon name="globe" /> Web Search
                    </:entry>
                  </.dropdown_menu>
                  <.input_group_button
                    type="submit"
                    variant="default"
                    size="icon-sm"
                    disabled={is_nil(@next_message) || @busy}
                    class="ml-auto"
                  ><LiveShadcn.Icon.icon name="arrow-up" /><span class="sr-only">Send</span></.input_group_button>
                </.input_group_addon>
              </.input_group>
            </form>
          </.card_footer>
        </.card>
        <div class="px-0.5 text-center text-xs text-muted-foreground">
          Streaming is simulated. `autoScroll` is enabled.
        </div>
      </div>
    </.message_scroller_provider>
    """
  end

  defp message_scroller_animation(assigns) do
    messages = Enum.take(@message_scroller_animation, length(assigns.message_scroller.animation))
    busy = assigns.message_scroller.animation_busy
    next_message = Enum.at(@message_scroller_animation, length(messages))

    assigns =
      assign(assigns,
        messages: messages,
        busy: busy,
        next_message: next_message,
        preset: assigns.message_scroller.animation_preset
      )

    ~H"""
    <div class="relative flex flex-col gap-4">
      <.card class="mx-auto h-140 w-full max-w-sm gap-0">
        <.card_header class="border-b">
          <.card_title>Animation</.card_title>
          <.card_description>
            Choose how user messages are animated when they are added to the conversation.
          </.card_description>
          <.card_action class="flex items-center gap-2">
            <.button
              type="button"
              variant="outline"
              size="icon"
              aria-label="Reset animated messages"
              disabled={@messages == [] || @busy}
              phx-click="message_scroller_reset"
              phx-value-example="animation"
            ><LiveShadcn.Icon.icon name="rotate-cw" /></.button>
          </.card_action>
        </.card_header>
        <.card_content class="min-h-0 flex-1 overflow-hidden p-0">
          <.empty :if={@messages == []} class="h-full">
            <.empty_header>
              <.empty_media variant="icon">
                <LiveShadcn.Icon.icon name="message-circle-dashed" />
              </.empty_media>
              <.empty_title>No Messages Yet</.empty_title>
              <.empty_description>
                Click the button below to send the first message.
              </.empty_description>
            </.empty_header>
          </.empty>
          <.message_scroller_provider :if={@messages != []}>
            <.message_scroller id="message-scroller-animation">
              <.message_scroller_viewport
                id="message-scroller-animation-viewport"
                controller="message-scroller-animation"
              >
                <.message_scroller_content aria-busy={to_string(@busy)} class="p-(--card-spacing)">
                  <.message_scroller_rows
                    messages={@messages}
                    animation_preset={@message_scroller.animation_preset}
                  />
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.message_scroller_provider>
        </.card_content>
        <.card_footer class="border-t">
          <form
            id="message-scroller-animation-preset"
            class="contents"
            phx-change="message_scroller_animation_preset"
          >
            <.select
              id="message-scroller-animation-select"
              name="preset"
              value={@preset}
              aria-label="Animation preset"
              side="top"
              align="start"
            >
              <:option value="fade" label="Fade" />
              <:option value="slide-up" label="Slide Up" />
              <:option value="slide-side" label="Slide Side" />
              <:option value="pop" label="Pop" />
              <:option value="spring-bounce" label="Spring Bounce" />
              <:option value="blur-fade" label="Blur Fade" />
              <:option value="scale-fade" label="Scale Fade" />
            </.select>
          </form>
          <.button
            type="button"
            size="icon"
            class="ml-auto"
            disabled={is_nil(@next_message) || @busy}
            phx-click="message_scroller_send"
            phx-value-example="animation"
          ><LiveShadcn.Icon.icon name="arrow-up" /><span class="sr-only">Send Message</span></.button>
        </.card_footer>
      </.card>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
        Select an animation then click send to see it in action.
      </div>
    </div>
    """
  end

  defp message_scroller_load_history(assigns), do: message_scroller_history(assigns)

  defp message_scroller_opening_position(assigns) do
    position = assigns.message_scroller.opening_position
    assigns = assign(assigns, position: position, messages: @message_scroller_opening_position)

    ~H"""
    <div class="relative flex flex-col gap-4">
      <.card class="mx-auto h-140 w-full max-w-sm gap-0">
        <.card_header class="gap-1 border-b">
          <.card_title>Opening Position</.card_title>
          <.card_description>Choose where a saved transcript opens.</.card_description>
        </.card_header>
        <.card_content class="flex-1 overflow-hidden p-0">
          <.message_scroller
            id="message-scroller-opening"
            default_scroll_position="end"
            data-lb-message-opening-hold="false"
          >
            <.message_scroller_viewport
              id="message-scroller-opening-viewport"
              controller="message-scroller-opening"
              default_scroll_position="end"
            >
              <.message_scroller_content class="p-(--card-spacing)">
                <.message_scroller_rows messages={@messages} anchor_role={:user} />
              </.message_scroller_content>
            </.message_scroller_viewport>
            <.message_scroller_button />
          </.message_scroller>
        </.card_content>
        <.card_footer class="flex items-center justify-center border-t">
          <.tabs
            id="message-scroller-opening-tabs"
            value={@position}
            class="w-full"
            list_class="w-full"
            phx-hook="OpeningPosition"
            data-lb-opening-position-target="message-scroller-opening"
          >
            <:tab value="start" label="start" panel={false} />
            <:tab value="end" label="end" panel={false} />
            <:tab value="last-anchor" label="last-anchor" panel={false} />
          </.tabs>
        </.card_footer>
      </.card>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-muted-foreground">
        Toggle the defaultScrollPosition to see where the transcript starts when you open the thread
      </div>
    </div>
    """
  end

  defp message_scroller_commands(assigns) do
    user_messages = Enum.filter(@message_scroller_commands, &(&1.role == :user))
    assigns = assign(assigns, messages: @message_scroller_commands, user_messages: user_messages)

    ~H"""
    <.message_scroller_provider default_scroll_position="end">
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Commands</.card_title>
            <.card_description>Drive the transcript from outside.</.card_description>
            <.card_action>
              <.dropdown_menu
                id="message-scroller-commands-menu"
                direct_trigger
                transient_controls
                trigger_variant="secondary"
                side="bottom"
                align="end"
                class="w-64"
              >
                <:trigger>Jump to...</:trigger>
                <:entry kind="label" section="conversations">Conversations</:entry>
                <:entry
                  :for={message <- @user_messages}
                  kind="item"
                  section="conversations"
                  value={message.id}
                  phx-click={
                    LiveBase.Scroller.scroll_to_message("message-scroller-commands", message.id,
                      align: "start",
                      behavior: "smooth"
                    )
                  }
                >
                  <span class="line-clamp-1 min-w-0">{message_scroller_trimmed_text(message.text)}</span>
                </:entry>
              </.dropdown_menu>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller
              id="message-scroller-commands"
              default_scroll_position="end"
              data-lb-message-opening-hold="false"
            >
              <.message_scroller_viewport
                id="message-scroller-commands-viewport"
                controller="message-scroller-commands"
              >
                <.message_scroller_content class="p-(--card-spacing)">
                  <.message_scroller_rows messages={@messages} />
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
        </.card>
        <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
          Use the controls to jump to any message in the conversation.
        </div>
      </div>
    </.message_scroller_provider>
    """
  end

  defp message_scroller_trimmed_text(text) when byte_size(text) > 42,
    do: binary_part(text, 0, 39) <> "..."

  defp message_scroller_trimmed_text(text), do: text

  defp message_scroller_visibility(assigns) do
    user_messages = Enum.filter(@message_scroller_visibility, &(&1.role == :user))

    assigns =
      assign(assigns, messages: @message_scroller_visibility, user_messages: user_messages)

    ~H"""
    <div class="relative flex flex-col gap-4">
      <div class="relative mx-auto w-full max-w-sm">
        <.card class="h-140 w-full gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Transcript Outline</.card_title>
            <.card_description>Track the current anchored turn.</.card_description>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller
              id="message-scroller-visibility"
              default_scroll_position="end"
              scroll_margin={12}
            >
              <.message_scroller_viewport
                id="message-scroller-visibility-viewport"
                controller="message-scroller-visibility"
              >
                <.message_scroller_content class="p-(--card-spacing)">
                  <.message_scroller_rows messages={@messages} />
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
        </.card>
        <div
          id="message-scroller-visibility-outline"
          data-message-scroller-outline
          data-message-scroller-controller="message-scroller-visibility"
          class="absolute top-1/2 -right-12 -translate-y-1/2"
        >
          <.hover_card_trigger
            id="message-scroller-visibility-outline-card"
            as="native-button"
            aria-label="Open transcript outline"
            class="flex h-9 w-9 flex-col items-center justify-center gap-1 rounded-md transition-colors outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <span
              :for={message <- @user_messages}
              id={"message-scroller-visibility-bar-#{message.id}"}
              data-message-scroller-outline-bar
              data-message-scroller-anchor-id={message.id}
              class="h-0.5 w-4 rounded-full bg-muted-foreground/40 data-[current=true]:bg-foreground"
            />
          </.hover_card_trigger>
          <.hover_card_content
            id="message-scroller-visibility-outline-card"
            side="left"
            align="center"
            offset={-28}
            class="flex w-64 flex-col gap-1 rounded-2xl p-1"
          >
            <button
              :for={message <- @user_messages}
              id={"message-scroller-visibility-choice-#{message.id}"}
              data-message-scroller-outline-choice
              data-message-scroller-anchor-id={message.id}
              type="button"
              class="flex min-h-7 items-center rounded-xl px-2 py-1.5 text-left text-sm transition-colors outline-none hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent focus-visible:text-accent-foreground aria-current:bg-accent aria-current:text-accent-foreground"
              phx-click={message_scroller_visibility_select(message.id)}
            >
              <span class="line-clamp-1 min-w-0">{message_scroller_trimmed_text(message.text)}</span>
            </button>
          </.hover_card_content>
        </div>
      </div>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-muted-foreground">
        Open the outline to jump between anchored turns as you read.
      </div>
    </div>
    """
  end

  defp message_scroller_visibility_select(id) do
    LiveBase.Scroller.scroll_to_message("message-scroller-visibility", id,
      align: "start",
      behavior: "smooth"
    )
  end

  defp message_scroller_scrollable(assigns) do
    messages =
      for index <- 1..12 do
        %{
          id: "scrollable-#{index}",
          role: if(rem(index, 2) == 1, do: :user, else: :assistant),
          text:
            if rem(index, 2) == 1 do
              "Review scroll checkpoint #{index}."
            else
              """
              Checkpoint #{index} is synced. The scrollable hook updates as the viewport moves.

              When the reader is at the first message, the footer should only point them down. Once they move into the middle of the transcript, it should explain that both directions are available.

              At the latest message, the footer should switch again and only point them back up.
              """
            end
        }
      end

    assigns = assign(assigns, messages: messages)

    ~H"""
    <div class="mx-auto flex w-full max-w-sm flex-col gap-4">
      <.card class="h-140 w-full gap-0 overflow-hidden">
        <.card_header class="gap-1 border-b">
          <.card_title>Scroll Status</.card_title>
          <.card_description>
            Where the reader can go scroll to based on current scroll position.
          </.card_description>
        </.card_header>
        <.message_scroller_provider default_scroll_position="start">
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller
              id="message-scroller-scrollable"
              default_scroll_position="start"
            >
              <.message_scroller_viewport
                id="message-scroller-scrollable-viewport"
                controller="message-scroller-scrollable"
                default_scroll_position="start"
              >
                <.message_scroller_content class="gap-4 p-(--card-spacing)">
                  <.message_scroller_rows
                    messages={@messages}
                    animation_preset="slide-up"
                  />
                </.message_scroller_content>
              </.message_scroller_viewport><.message_scroller_button />
            </.message_scroller>
          </.card_content>
          <.card_footer
            data-lb-message-scroll-state-for="message-scroller-scrollable"
            class="justify-center border-t text-center text-sm text-muted-foreground"
          >
            <span data-lb-message-scroll-status="start end" hidden>You can scroll both ways.</span>
            <span data-lb-message-scroll-status="end">You are at the top. You can only scroll down.</span>
            <span data-lb-message-scroll-status="start" hidden>You are at the bottom. You can only scroll up.</span>
            <span data-lb-message-scroll-status="none" hidden>All messages fit in the viewport.</span>
          </.card_footer>
        </.message_scroller_provider>
      </.card>
      <div class="px-0.5 text-center text-xs text-muted-foreground">
        Scroll the transcript to see the footer update.
      </div>
    </div>
    """
  end

  attr :messages, :list, required: true
  attr :anchor_role, :atom, default: nil
  attr :animation_preset, :string, default: nil

  defp message_scroller_rows(assigns) do
    ~H"""
    <.message_scroller_item
      :for={message <- @messages}
      message_id={message.id}
      scroll_anchor={message.role == (@anchor_role || :user)}
      data-lb-message-animation={if message.role == :user && @animation_preset, do: @animation_preset}
    >
      <.message align={if(message.role == :user, do: "end", else: "start")}>
        <.message_content>
          <.bubble variant={if(message.role == :user, do: "muted", else: "ghost")}>
            <.bubble_content class="space-y-2">
              <p :for={part <- message_parts(message.text)} class="whitespace-pre-wrap">{part}</p>
            </.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
    </.message_scroller_item>
    """
  end

  defp message_parts(text) do
    text
    |> String.split(~r/\n\s*\n/)
    |> Enum.map(&String.trim/1)
  end

  attr :items, :list, required: true
  attr :turn, :atom, required: true

  defp group_chat_rows(assigns) do
    ~H"""
    <.message_scroller_item
      :for={item <- @items}
      message_id={item.id}
      scroll_anchor={item.scroll_anchor}
    >
      <.message align={if(item.sender == "Grace", do: "end", else: "start")}>
        <.message_content>
          <.message_header :if={item.sender != "Grace"}>{item.sender}</.message_header><.bubble variant={
            cond do
              item.sender == "Grace" -> "muted"
              item.role == :assistant -> "ghost"
              true -> "tinted"
            end
          }>
            <.bubble_content>{item.text}</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
    </.message_scroller_item>
    <.message_scroller_item :if={@turn in [:marker, :message]} scroll_anchor>
      <.marker variant="separator">
        <.marker_content>Rocky has joined the chat</.marker_content>
      </.marker>
    </.message_scroller_item>
    <.message_scroller_item :if={@turn == :message} message_id="group-5">
      <.message align="start">
        <.message_content>
          <.message_header>Rocky</.message_header><.bubble variant="tinted">
            <.bubble_content>
              Amaze. Astrophage eats light, makes heat, goes to carbon dioxide. Rocky has fuel model. Grace is smart.
            </.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
    </.message_scroller_item>
    """
  end

  defp message_scroller_history(assigns) do
    visible_count = assigns.message_scroller.load_history
    messages = Enum.take(@message_scroller_history, -visible_count)
    can_load_history = visible_count < length(@message_scroller_history)

    default_scroll_position =
      if assigns.message_scroller.load_history_generation > 0, do: "start", else: "end"

    assigns =
      assign(assigns,
        messages: messages,
        can_load_history: can_load_history,
        can_reset: visible_count != 5,
        generation: assigns.message_scroller.load_history_generation,
        default_scroll_position: default_scroll_position
      )

    ~H"""
    <.message_scroller_provider>
      <div class="relative flex flex-col gap-4">
        <.card class="mx-auto h-140 w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Load History</.card_title>
            <.card_description>Prepended messages keep your place.</.card_description>
            <.card_action>
              <.tooltip
                id="message-scroller-load-history-reset-tooltip"
                trigger_label="Reset loaded messages"
                trigger_size="icon"
                disabled={not @can_reset}
                trigger_click={
                  Phoenix.LiveView.JS.push("message_scroller_reset",
                    value: %{example: "load-history"}
                  )
                }
              >
                <:trigger><LiveShadcn.Icon.icon name="rotate-cw" /></:trigger>
                Reset
              </.tooltip>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller
              id={"message-scroller-load-history-#{@generation}"}
              data-lb-message-opening-generation={@generation}
              default_scroll_position={@default_scroll_position}
            >
              <.message_scroller_viewport
                id={"message-scroller-load-history-viewport-#{@generation}"}
                controller={"message-scroller-load-history-#{@generation}"}
                default_scroll_position={@default_scroll_position}
              >
                <.message_scroller_content class="p-(--card-spacing)">
                  <.message_scroller_history_rows messages={@messages} />
                  <.message_scroller_item scroll_anchor={false}>
                    <.marker variant="separator">
                      <.marker_content>End of Conversation</.marker_content>
                    </.marker>
                  </.message_scroller_item>
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
          <.card_footer class="flex flex-col items-center gap-2 border-t">
            <.button
              type="button"
              disabled={not @can_load_history}
              class="w-full"
              variant="secondary"
              phx-click="message_scroller_load_history"
            >{if @can_load_history, do: "Load History", else: "History Loaded"}</.button>
            <p class="text-xs text-muted-foreground">
              Restore earlier messages while keeping your place.
            </p>
          </.card_footer>
        </.card>
        <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
          Click Load History to load the entire conversation
        </div>
      </div>
    </.message_scroller_provider>
    <Sonner.toaster
      id="message-scroller-load-history-toast"
      dismiss="dismiss_toast"
      duration={4000}
    >
      <:toast
        :for={notice <- @toast_examples["message-scroller-load-history"]}
        id={notice.id}
        type={notice.type}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </Sonner.toaster>
    """
  end

  attr :messages, :list, required: true

  defp message_scroller_history_rows(assigns) do
    ~H"""
    <.message_scroller_item
      :for={message <- @messages}
      message_id={message.id}
      scroll_anchor={false}
    >
      <.message align={if(message.role == :user, do: "end", else: "start")}>
        <.message_content>
          <.bubble variant={if(message.role == :user, do: "muted", else: "ghost")}>
            <.bubble_content class="space-y-2">
              <p :for={part <- message_parts(message.text)} class="whitespace-pre-wrap">{part}</p>
            </.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
    </.message_scroller_item>
    """
  end

  defp sonner_basic(assigns) do
    ~H"""
    <.button variant="outline" class="w-fit" phx-click="sonner_add" phx-value-example="basic">
      Show Toast
    </.button>
    <Sonner.toaster id="sonner-basic" dismiss="dismiss_sonner_toast">
      <:toast :for={notice <- @sonner_examples["basic"]} id={notice.id} title={notice.title}>
        {notice.description}
      </:toast>
    </Sonner.toaster>
    """
  end

  defp sonner_with_description(assigns) do
    ~H"""
    <.button
      variant="outline"
      class="w-fit"
      phx-click="sonner_add"
      phx-value-example="with-description"
    >
      Show Toast
    </.button>
    <Sonner.toaster id="sonner-with-description" dismiss="dismiss_sonner_toast">
      <:toast
        :for={notice <- @sonner_examples["with-description"]}
        id={notice.id}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </Sonner.toaster>
    """
  end

  defp resizable_default(assigns) do
    ~H"""
    <.resizable_panel_group
      id="resizable-default"
      orientation="horizontal"
      class="max-w-sm rounded-lg border"
    >
      <.resizable_panel default_size="50%">
        <div class="flex h-[200px] items-center justify-center p-6">
          <span class="font-semibold">One</span>
        </div>
      </.resizable_panel>
      <.resizable_handle with_handle />
      <.resizable_panel default_size="50%">
        <.resizable_panel_group id="resizable-default-nested" orientation="vertical">
          <.resizable_panel default_size="25%" orientation="vertical">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Two</span>
            </div>
          </.resizable_panel>
          <.resizable_handle orientation="horizontal" value_now={25} with_handle />
          <.resizable_panel default_size="75%" orientation="vertical">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Three</span>
            </div>
          </.resizable_panel>
        </.resizable_panel_group>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  defp resizable_vertical(assigns) do
    ~H"""
    <.resizable_panel_group
      id="resizable-vertical"
      orientation="vertical"
      class="min-h-[200px] max-w-sm rounded-lg border"
    >
      <.resizable_panel default_size="25%" orientation="vertical">
        <div class="flex h-full items-center justify-center p-6">
          <span class="font-semibold">Header</span>
        </div>
      </.resizable_panel>
      <.resizable_handle orientation="horizontal" value_now={25} />
      <.resizable_panel default_size="75%" orientation="vertical">
        <div class="flex h-full items-center justify-center p-6">
          <span class="font-semibold">Content</span>
        </div>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  defp resizable_handle_example(assigns) do
    ~H"""
    <.resizable_panel_group
      id="resizable-handle"
      orientation="horizontal"
      class="min-h-[200px] max-w-sm rounded-lg border"
    >
      <.resizable_panel default_size="25%">
        <div class="flex h-full items-center justify-center p-6">
          <span class="font-semibold">Sidebar</span>
        </div>
      </.resizable_panel>
      <.resizable_handle value_now={25} with_handle />
      <.resizable_panel default_size="75%">
        <div class="flex h-full items-center justify-center p-6">
          <span class="font-semibold">Content</span>
        </div>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  defp resizable_rtl(assigns) do
    ~H"""
    <.resizable_panel_group
      id="resizable-rtl"
      orientation="horizontal"
      class="max-w-sm rounded-lg border"
      dir="rtl"
    >
      <.resizable_panel default_size="50%">
        <div class="flex h-[200px] items-center justify-center p-6">
          <span class="font-semibold">واحد</span>
        </div>
      </.resizable_panel>
      <.resizable_handle with_handle />
      <.resizable_panel default_size="50%">
        <.resizable_panel_group id="resizable-rtl-nested" orientation="vertical" dir="rtl">
          <.resizable_panel default_size="25%" orientation="vertical">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">اثنان</span>
            </div>
          </.resizable_panel>
          <.resizable_handle orientation="horizontal" value_now={25} with_handle />
          <.resizable_panel default_size="75%" orientation="vertical">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">ثلاثة</span>
            </div>
          </.resizable_panel>
        </.resizable_panel_group>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  defp alert_default(assigns) do
    ~H"""
    <div class="grid w-full max-w-md items-start gap-4">
      <.alert>
        <LiveShadcn.Icon.icon name="circle-check" />
        <.alert_title>Payment successful</.alert_title>
        <.alert_description>
          Your payment of $29.99 has been processed. A receipt has been sent to your email address.
        </.alert_description>
      </.alert>
      <.alert>
        <LiveShadcn.Icon.icon name="info" />
        <.alert_title>New feature available</.alert_title>
        <.alert_description>
          We've added dark mode support. You can enable it in your account settings.
        </.alert_description>
      </.alert>
    </div>
    """
  end

  defp alert_basic(assigns) do
    ~H"""
    <.alert class="max-w-md">
      <LiveShadcn.Icon.icon name="circle-check" />
      <.alert_title>Account updated successfully</.alert_title>
      <.alert_description>
        Your profile information has been saved. Changes will be reflected immediately.
      </.alert_description>
    </.alert>
    """
  end

  defp alert_destructive(assigns) do
    ~H"""
    <.alert variant="destructive" class="max-w-md">
      <LiveShadcn.Icon.icon name="circle-alert" />
      <.alert_title>Payment failed</.alert_title>
      <.alert_description>
        Your payment could not be processed. Please check your payment method and try again.
      </.alert_description>
    </.alert>
    """
  end

  defp alert_action_example(assigns) do
    ~H"""
    <.alert class="max-w-md">
      <.alert_title>Dark mode is now available</.alert_title>
      <.alert_description>
        Enable it under your profile settings to get started.
      </.alert_description>
      <.alert_action>
        <.button size="xs">Enable</.button>
      </.alert_action>
    </.alert>
    """
  end

  defp alert_colors(assigns) do
    ~H"""
    <.alert class="max-w-md border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-50">
      <LiveShadcn.Icon.icon name="triangle-alert" />
      <.alert_title>Your subscription will expire in 3 days.</.alert_title>
      <.alert_description>
        Renew now to avoid service interruption or upgrade to a paid plan to continue using the service.
      </.alert_description>
    </.alert>
    """
  end

  defp alert_rtl(assigns) do
    ~H"""
    <div class="grid w-full max-w-md items-start gap-4" dir="rtl">
      <.alert>
        <LiveShadcn.Icon.icon name="circle-check" />
        <.alert_title>تم الدفع بنجاح</.alert_title>
        <.alert_description>
          تمت معالجة دفعتك البالغة 29.99 دولارًا. تم إرسال إيصال إلى عنوان بريدك الإلكتروني.
        </.alert_description>
      </.alert>
      <.alert>
        <LiveShadcn.Icon.icon name="info" />
        <.alert_title>ميزة جديدة متاحة</.alert_title>
        <.alert_description>
          لقد أضفنا دعم الوضع الداكن. يمكنك تفعيله في إعدادات حسابك.
        </.alert_description>
      </.alert>
    </div>
    """
  end

  defp badge_default(assigns) do
    ~H"""
    <div class="flex w-full flex-wrap justify-center gap-2">
      <.badge>Badge</.badge>
      <.badge variant="secondary">Secondary</.badge>
      <.badge variant="destructive">Destructive</.badge>
      <.badge variant="outline">Outline</.badge>
    </div>
    """
  end

  defp badge_variants(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.badge>Default</.badge>
      <.badge variant="secondary">Secondary</.badge>
      <.badge variant="destructive">Destructive</.badge>
      <.badge variant="outline">Outline</.badge>
      <.badge variant="ghost">Ghost</.badge>
    </div>
    """
  end

  defp badge_icon(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.badge variant="secondary">
        <LiveShadcn.Icon.icon name="badge-check" data-icon="inline-start" /> Verified
      </.badge>
      <.badge variant="outline">
        Bookmark <LiveShadcn.Icon.icon name="bookmark" data-icon="inline-end" />
      </.badge>
    </div>
    """
  end

  defp badge_spinner(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.badge variant="destructive">
        <.spinner data-icon="inline-start" /> Deleting
      </.badge>
      <.badge variant="secondary">
        Generating <.spinner data-icon="inline-end" />
      </.badge>
    </div>
    """
  end

  defp badge_link(assigns) do
    ~H"""
    <.badge href="#link">
      Open Link <LiveShadcn.Icon.icon name="arrow-up-right" data-icon="inline-end" />
    </.badge>
    """
  end

  defp badge_colors(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.badge class="bg-blue-50 text-blue-700 dark:bg-blue-950 dark:text-blue-300">Blue</.badge>
      <.badge class="bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300">
        Green
      </.badge>
      <.badge class="bg-sky-50 text-sky-700 dark:bg-sky-950 dark:text-sky-300">Sky</.badge>
      <.badge class="bg-purple-50 text-purple-700 dark:bg-purple-950 dark:text-purple-300">
        Purple
      </.badge>
      <.badge class="bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300">Red</.badge>
    </div>
    """
  end

  defp badge_rtl(assigns) do
    ~H"""
    <div class="flex w-full flex-wrap justify-center gap-2" dir="rtl">
      <.badge>شارة</.badge>
      <.badge variant="secondary">ثانوي</.badge>
      <.badge variant="destructive">مدمر</.badge>
      <.badge variant="outline">مخطط</.badge>
      <.badge variant="secondary">
        <LiveShadcn.Icon.icon name="badge-check" data-icon="inline-start" /> متحقق
      </.badge>
      <.badge variant="outline">
        إشارة مرجعية <LiveShadcn.Icon.icon name="bookmark" data-icon="inline-end" />
      </.badge>
    </div>
    """
  end

  defp breadcrumb_default(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="#">Home</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.dropdown_menu
            id="breadcrumb-default-menu"
            align="start"
            grouped
            trigger_variant="ghost"
            trigger_size="icon-sm"
          >
            <:trigger>
              <.breadcrumb_ellipsis />
              <span class="sr-only">Toggle menu</span>
            </:trigger>
            <:entry kind="item" value="documentation">Documentation</:entry>
            <:entry kind="item" value="themes">Themes</:entry>
            <:entry kind="item" value="github">GitHub</:entry>
          </.dropdown_menu>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_link href="#">Components</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_basic(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item><.breadcrumb_link href="#">Home</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item><.breadcrumb_link href="#">Components</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_link_example(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="#link-component">Home</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_link href="#link-component">Components</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_separator_example(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item><.breadcrumb_link href="/">Home</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.breadcrumb_link href="/components">Components</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_ellipsis_example(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item><.breadcrumb_link href="/">Home</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item><.breadcrumb_ellipsis /></.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_link href="/docs/components">Components</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_dropdown(assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item><.breadcrumb_link href="/">Home</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.dropdown_menu
            id="breadcrumb-dropdown-menu"
            align="start"
            grouped
            trigger_class="flex items-center gap-1"
          >
            <:trigger>
              Components
              <LiveShadcn.Icon.icon name="chevron-down" data-icon="inline-end" class="size-3.5" />
            </:trigger>
            <:entry kind="item" value="documentation">Documentation</:entry>
            <:entry kind="item" value="themes">Themes</:entry>
            <:entry kind="item" value="github">GitHub</:entry>
          </.dropdown_menu>
        </.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp breadcrumb_rtl(assigns) do
    ~H"""
    <.breadcrumb dir="rtl">
      <.breadcrumb_list>
        <.breadcrumb_item><.breadcrumb_link href="/">الرئيسية</.breadcrumb_link></.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.dropdown_menu
            id="breadcrumb-rtl-menu"
            align="end"
            grouped
            trigger_class="flex items-center gap-1"
            content_attrs={%{dir: "rtl", "data-lang": "ar"}}
          >
            <:trigger>
              المكونات
              <LiveShadcn.Icon.icon name="chevron-down" data-icon="inline-end" class="size-3.5" />
            </:trigger>
            <:entry kind="item" value="documentation">التوثيق</:entry>
            <:entry kind="item" value="themes">السمات</:entry>
            <:entry kind="item" value="github">جيت هاب</:entry>
          </.dropdown_menu>
        </.breadcrumb_item>
        <.breadcrumb_separator><LiveShadcn.Icon.icon name="dot" /></.breadcrumb_separator>
        <.breadcrumb_item>
          <.breadcrumb_page>مسار التنقل</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  defp button_demo(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2 md:flex-row">
      <.button variant="outline">Button</.button>
      <.button variant="outline" size="icon" aria-label="Submit">
        <LiveShadcn.Icon.icon name="arrow-up" />
      </.button>
    </div>
    """
  end

  defp button_size(assigns) do
    ~H"""
    <div class="flex flex-col items-start gap-8 sm:flex-row">
      <div class="flex items-start gap-2">
        <.button size="xs" variant="outline">Extra Small</.button>
        <.button size="icon-xs" aria-label="Submit" variant="outline">
          <LiveShadcn.Icon.icon name="arrow-up-right" />
        </.button>
      </div>
      <div class="flex items-start gap-2">
        <.button size="sm" variant="outline">Small</.button>
        <.button size="icon-sm" aria-label="Submit" variant="outline">
          <LiveShadcn.Icon.icon name="arrow-up-right" />
        </.button>
      </div>
      <div class="flex items-start gap-2">
        <.button variant="outline">Default</.button>
        <.button size="icon" aria-label="Submit" variant="outline">
          <LiveShadcn.Icon.icon name="arrow-up-right" />
        </.button>
      </div>
      <div class="flex items-start gap-2">
        <.button variant="outline" size="lg">Large</.button>
        <.button size="icon-lg" aria-label="Submit" variant="outline">
          <LiveShadcn.Icon.icon name="arrow-up-right" />
        </.button>
      </div>
    </div>
    """
  end

  defp button_default_example(assigns) do
    ~H"""
    <.button>Button</.button>
    """
  end

  defp button_outline(assigns) do
    ~H"""
    <.button variant="outline">Outline</.button>
    """
  end

  defp button_secondary(assigns) do
    ~H"""
    <.button variant="secondary">Secondary</.button>
    """
  end

  defp button_ghost(assigns) do
    ~H"""
    <.button variant="ghost">Ghost</.button>
    """
  end

  defp button_destructive(assigns) do
    ~H"""
    <.button variant="destructive">Destructive</.button>
    """
  end

  defp button_link_example(assigns) do
    ~H"""
    <.button variant="link">Link</.button>
    """
  end

  defp button_icon(assigns) do
    ~H"""
    <.button variant="outline" size="icon">
      <LiveShadcn.Icon.icon name="circle-fading-arrow-up" />
    </.button>
    """
  end

  defp button_with_icon(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.button variant="outline">
        <.tabler_icon name="git-branch" data-icon="inline-start" /> New Branch
      </.button>
      <.button variant="outline">
        Fork <.tabler_icon name="git-fork" data-icon="inline-end" />
      </.button>
    </div>
    """
  end

  defp button_rounded(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.button class="rounded-full">Get Started</.button>
      <.button variant="outline" size="icon" class="rounded-full">
        <LiveShadcn.Icon.icon name="arrow-up" />
      </.button>
    </div>
    """
  end

  defp button_spinner(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.button variant="outline" disabled>
        <.spinner data-icon="inline-start" /> Generating
      </.button>
      <.button variant="secondary" disabled>
        Downloading <.spinner data-icon="inline-start" />
      </.button>
    </div>
    """
  end

  defp button_group_demo_example(assigns) do
    assigns =
      assign(assigns, :button_label_items, [
        %{
          kind: "radio-group",
          group: "label",
          value: "personal",
          items: [
            %{value: "personal", label: "Personal"},
            %{value: "work", label: "Work"},
            %{value: "other", label: "Other"}
          ]
        }
      ])

    ~H"""
    <.button_group>
      <.button_group class="hidden sm:flex">
        <.button variant="outline" size="icon" aria-label="Go Back">
          <LiveShadcn.Icon.icon name="arrow-left" />
        </.button>
      </.button_group>
      <.button_group>
        <.button variant="outline">Archive</.button>
        <.button variant="outline">Report</.button>
      </.button_group>
      <.button_group>
        <.button variant="outline">Snooze</.button>
        <.dropdown_menu
          id="button-more-options"
          direct_trigger
          align="end"
          class="w-40"
          grouped
          trigger_variant="outline"
          trigger_size="icon"
          trigger_attrs={%{"aria-label" => "More Options"}}
        >
          <:trigger><LiveShadcn.Icon.icon name="ellipsis" /></:trigger>
          <:entry kind="item" value="mark-read">
            <LiveShadcn.Icon.icon name="mail-check" /> Mark as Read
          </:entry>
          <:entry kind="item" value="archive">
            <LiveShadcn.Icon.icon name="archive" /> Archive
          </:entry>
          <:entry kind="separator" />
          <:entry kind="item" value="snooze">
            <LiveShadcn.Icon.icon name="clock" /> Snooze
          </:entry>
          <:entry kind="item" value="calendar">
            <LiveShadcn.Icon.icon name="calendar-plus" /> Add to Calendar
          </:entry>
          <:entry kind="item" value="list">
            <LiveShadcn.Icon.icon name="list-filter" /> Add to List
          </:entry>
          <:entry kind="submenu" value="label" items={@button_label_items}>
            <LiveShadcn.Icon.icon name="tag" /> Label As...
          </:entry>
          <:entry kind="separator" />
          <:entry kind="item" value="trash" variant="destructive">
            <LiveShadcn.Icon.icon name="trash-2" /> Trash
          </:entry>
        </.dropdown_menu>
      </.button_group>
    </.button_group>
    """
  end

  defp button_render(assigns) do
    ~H"""
    <a href="#" class={LiveShadcn.UI.Button.button_class(variant: "secondary", size: "sm")}>
      Login
    </a>
    """
  end

  defp button_rtl(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2 md:flex-row" dir="rtl">
      <.button variant="outline">زر</.button>
      <.button variant="destructive">حذف</.button>
      <.button variant="outline">
        إرسال
        <LiveShadcn.Icon.icon
          name="arrow-right"
          class="rtl:rotate-180"
          data-icon="inline-end"
        />
      </.button>
      <.button variant="outline" size="icon" aria-label="Add">
        <LiveShadcn.Icon.icon name="plus" />
      </.button>
      <.button variant="secondary" disabled>
        <.spinner data-icon="inline-start" /> جاري التحميل
      </.button>
    </div>
    """
  end

  defp checkbox_default(assigns) do
    ~H"""
    <.field_group class="max-w-sm">
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox" name="terms-checkbox" />
        <.label for="terms-checkbox">Accept terms and conditions</.label>
      </.field>
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox-2" name="terms-checkbox-2" checked />
        <.field_content>
          <.field_label for="terms-checkbox-2">Accept terms and conditions</.field_label>
          <.field_description>
            By clicking this checkbox, you agree to the terms.
          </.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal" data-disabled="true">
        <.checkbox id="toggle-checkbox" name="toggle-checkbox" disabled />
        <.field_label for="toggle-checkbox">Enable notifications</.field_label>
      </.field>
      <.field_label id="toggle-checkbox-2-label">
        <.field orientation="horizontal">
          <.checkbox
            id="toggle-checkbox-2"
            name="toggle-checkbox-2"
            aria-labelledby="toggle-checkbox-2-label"
          />
          <.field_content>
            <.field_title>Enable notifications</.field_title>
            <.field_description>
              You can enable or disable notifications at any time.
            </.field_description>
          </.field_content>
        </.field>
      </.field_label>
    </.field_group>
    """
  end

  defp checkbox_basic(assigns) do
    ~H"""
    <.field_group class="mx-auto w-56">
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox-basic" name="terms-checkbox-basic" />
        <.field_label for="terms-checkbox-basic">Accept terms and conditions</.field_label>
      </.field>
    </.field_group>
    """
  end

  defp checkbox_description(assigns) do
    ~H"""
    <.field_group class="mx-auto w-72">
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox-desc" name="terms-checkbox-desc" checked />
        <.field_content>
          <.field_label for="terms-checkbox-desc">Accept terms and conditions</.field_label>
          <.field_description>
            By clicking this checkbox, you agree to the terms and conditions.
          </.field_description>
        </.field_content>
      </.field>
    </.field_group>
    """
  end

  defp checkbox_disabled(assigns) do
    ~H"""
    <.field_group class="mx-auto w-56">
      <.field orientation="horizontal" data-disabled="true">
        <.checkbox id="toggle-checkbox-disabled" name="toggle-checkbox-disabled" disabled />
        <.field_label for="toggle-checkbox-disabled">Enable notifications</.field_label>
      </.field>
    </.field_group>
    """
  end

  defp checkbox_invalid(assigns) do
    ~H"""
    <.field_group class="mx-auto w-56">
      <.field orientation="horizontal" data-invalid="true">
        <.checkbox
          id="terms-checkbox-invalid"
          name="terms-checkbox-invalid"
          aria-invalid="true"
        />
        <.field_label for="terms-checkbox-invalid">Accept terms and conditions</.field_label>
      </.field>
    </.field_group>
    """
  end

  defp checkbox_group(assigns) do
    ~H"""
    <.field_set>
      <.field_legend variant="label">Show these items on the desktop:</.field_legend>
      <.field_description>Select the items you want to show on the desktop.</.field_description>
      <.field_group class="gap-3">
        <.field orientation="horizontal">
          <.checkbox
            id="finder-pref-9k2-hard-disks-ljj-checkbox"
            name="finder-pref-9k2-hard-disks-ljj-checkbox"
            checked
          />
          <.field_label for="finder-pref-9k2-hard-disks-ljj-checkbox" class="font-normal">
            Hard disks
          </.field_label>
        </.field>
        <.field orientation="horizontal">
          <.checkbox
            id="finder-pref-9k2-external-disks-1yg-checkbox"
            name="finder-pref-9k2-external-disks-1yg-checkbox"
            checked
          />
          <.field_label for="finder-pref-9k2-external-disks-1yg-checkbox" class="font-normal">
            External disks
          </.field_label>
        </.field>
        <.field orientation="horizontal">
          <.checkbox
            id="finder-pref-9k2-cds-dvds-fzt-checkbox"
            name="finder-pref-9k2-cds-dvds-fzt-checkbox"
          />
          <.field_label for="finder-pref-9k2-cds-dvds-fzt-checkbox" class="font-normal">
            CDs, DVDs, and iPods
          </.field_label>
        </.field>
        <.field orientation="horizontal">
          <.checkbox
            id="finder-pref-9k2-connected-servers-6l2-checkbox"
            name="finder-pref-9k2-connected-servers-6l2-checkbox"
          />
          <.field_label for="finder-pref-9k2-connected-servers-6l2-checkbox" class="font-normal">
            Connected servers
          </.field_label>
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  defp checkbox_table(assigns) do
    assigns =
      assign(assigns, :checkbox_rows, [
        %{id: "1", name: "Sarah Chen", email: "sarah.chen@example.com", role: "Admin"},
        %{id: "2", name: "Marcus Rodriguez", email: "marcus.rodriguez@example.com", role: "User"},
        %{id: "3", name: "Priya Patel", email: "priya.patel@example.com", role: "User"},
        %{id: "4", name: "David Kim", email: "david.kim@example.com", role: "Editor"}
      ])

    ~H"""
    <.table id="checkbox-table" phx-hook="CheckboxTable">
      <.table_header>
        <.table_row>
          <.table_head class="w-8">
            <.checkbox id="select-all-checkbox" name="select-all-checkbox" data-select-all />
          </.table_head>
          <.table_head>Name</.table_head>
          <.table_head>Email</.table_head>
          <.table_head>Role</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={row <- @checkbox_rows} data-state={if(row.id == "1", do: "selected")}>
          <.table_cell>
            <.checkbox
              id={"row-#{row.id}-checkbox"}
              name={"row-#{row.id}-checkbox"}
              checked={row.id == "1"}
              data-row-id={row.id}
            />
          </.table_cell>
          <.table_cell class="font-medium">{row.name}</.table_cell>
          <.table_cell>{row.email}</.table_cell>
          <.table_cell>{row.role}</.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  defp checkbox_rtl(assigns) do
    ~H"""
    <.field_group class="max-w-sm" dir="rtl">
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox-rtl" name="terms-checkbox" dir="rtl" />
        <.label for="terms-checkbox-rtl">قبول الشروط والأحكام</.label>
      </.field>
      <.field orientation="horizontal">
        <.checkbox id="terms-checkbox-2-rtl" name="terms-checkbox-2" checked dir="rtl" />
        <.field_content>
          <.field_label for="terms-checkbox-2-rtl">قبول الشروط والأحكام</.field_label>
          <.field_description>بالنقر على هذا المربع، فإنك توافق على الشروط.</.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal" data-disabled="true">
        <.checkbox id="toggle-checkbox-rtl" name="toggle-checkbox" disabled dir="rtl" />
        <.field_label for="toggle-checkbox-rtl">تفعيل الإشعارات</.field_label>
      </.field>
      <.field_label id="toggle-checkbox-2-rtl-label">
        <.field orientation="horizontal">
          <.checkbox
            id="toggle-checkbox-2"
            name="toggle-checkbox-2"
            aria-labelledby="toggle-checkbox-2-rtl-label"
          />
          <.field_content>
            <.field_title>تفعيل الإشعارات</.field_title>
            <.field_description>
              يمكنك تفعيل أو إلغاء تفعيل الإشعارات في أي وقت.
            </.field_description>
          </.field_content>
        </.field>
      </.field_label>
    </.field_group>
    """
  end

  defp hover_card_default(assigns) do
    ~H"""
    <.hover_card id="nextjs" class="flex w-64 flex-col gap-0.5">
      <:trigger>Hover Here</:trigger>
      <div class="font-semibold">@nextjs</div>
      <div>The React Framework – created and maintained by @vercel.</div>
      <div class="mt-1 text-xs text-muted-foreground">Joined December 2021</div>
    </.hover_card>
    """
  end

  defp hover_card_sides(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-center gap-2">
      <.hover_card
        :for={side <- ~w(left top bottom right)}
        id={"hover-card-#{side}"}
        side={side}
        delay={100}
        trigger_variant="outline"
        trigger_class="capitalize"
      >
        <:trigger>{side}</:trigger>
        <div class="flex flex-col gap-1">
          <h4 class="font-medium">Hover Card</h4>
          <p>This hover card appears on the {side} side of the trigger.</p>
        </div>
      </.hover_card>
    </div>
    """
  end

  defp hover_card_rtl(assigns) do
    ~H"""
    <div class="grid gap-4">
      <div class="flex flex-wrap justify-center gap-2">
        <.hover_card
          :for={
            {side, label} <- [
              {"left", "يسار"},
              {"top", "أعلى"},
              {"bottom", "أسفل"},
              {"right", "يمين"}
            ]
          }
          id={"hover-card-rtl-#{side}"}
          side={side}
          dir="rtl"
          trigger_variant="outline"
          class="flex w-64 flex-col gap-1"
        >
          <:trigger>{label}</:trigger>
          <div class="font-semibold">سماعات لاسلكية</div>
          <div class="text-sm text-muted-foreground">٩٩.٩٩ $</div>
        </.hover_card>
      </div>
      <div class="flex flex-wrap justify-center gap-2">
        <.hover_card
          :for={{side, label} <- [{"inline-start", "بداية السطر"}, {"inline-end", "نهاية السطر"}]}
          id={"hover-card-rtl-#{side}"}
          side={side}
          dir="rtl"
          trigger_variant="outline"
          class="flex w-64 flex-col gap-1"
        >
          <:trigger>{label}</:trigger>
          <div class="font-semibold">سماعات لاسلكية</div>
          <div class="text-sm text-muted-foreground">٩٩.٩٩ $</div>
        </.hover_card>
      </div>
    </div>
    """
  end

  defp input_default(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-demo-api-key">API Key</.field_label>
      <.input id="input-demo-api-key" type="password" placeholder="sk-..." />
      <.field_description>Your API key is encrypted and stored securely.</.field_description>
    </.field>
    """
  end

  defp input_basic(assigns) do
    ~H"""
    <.input placeholder="Enter text" />
    """
  end

  defp input_field(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-field-username">Username</.field_label>
      <.input id="input-field-username" type="text" placeholder="Enter your username" />
      <.field_description>Choose a unique username for your account.</.field_description>
    </.field>
    """
  end

  defp input_fieldgroup(assigns) do
    ~H"""
    <.field_group>
      <.field>
        <.field_label for="fieldgroup-name">Name</.field_label>
        <.input id="fieldgroup-name" placeholder="Jordan Lee" />
      </.field>
      <.field>
        <.field_label for="fieldgroup-email">Email</.field_label>
        <.input id="fieldgroup-email" type="email" placeholder="name@example.com" />
        <.field_description>We'll send updates to this address.</.field_description>
      </.field>
      <.field orientation="horizontal">
        <.button type="reset" variant="outline">Reset</.button>
        <.button type="submit">Submit</.button>
      </.field>
    </.field_group>
    """
  end

  defp input_disabled(assigns) do
    ~H"""
    <.field data-disabled="true">
      <.field_label for="input-demo-disabled">Email</.field_label>
      <.input id="input-demo-disabled" type="email" placeholder="Email" disabled />
      <.field_description>This field is currently disabled.</.field_description>
    </.field>
    """
  end

  defp input_invalid(assigns) do
    ~H"""
    <.field data-invalid="true">
      <.field_label for="input-invalid">Invalid Input</.field_label>
      <.input id="input-invalid" placeholder="Error" aria-invalid="true" />
      <.field_description>This field contains validation errors.</.field_description>
    </.field>
    """
  end

  defp input_file(assigns) do
    ~H"""
    <.field>
      <.field_label for="picture">Picture</.field_label>
      <.input id="picture" type="file" />
      <.field_description>Select a picture to upload.</.field_description>
    </.field>
    """
  end

  defp input_inline(assigns) do
    ~H"""
    <.field orientation="horizontal">
      <.input type="search" placeholder="Search..." />
      <.button>Search</.button>
    </.field>
    """
  end

  defp input_grid(assigns) do
    ~H"""
    <.field_group class="grid max-w-sm grid-cols-2">
      <.field>
        <.field_label for="first-name">First Name</.field_label>
        <.input id="first-name" placeholder="Jordan" />
      </.field>
      <.field>
        <.field_label for="last-name">Last Name</.field_label>
        <.input id="last-name" placeholder="Lee" />
      </.field>
    </.field_group>
    """
  end

  defp input_required(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-required">
        Required Field <span class="text-destructive">*</span>
      </.field_label>
      <.input id="input-required" placeholder="This field is required" required />
      <.field_description>This field must be filled out.</.field_description>
    </.field>
    """
  end

  defp input_badge(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-badge">
        Webhook URL
        <.badge variant="secondary" class="ml-auto">Beta</.badge>
      </.field_label>
      <.input id="input-badge" type="url" placeholder="https://api.example.com/webhook" />
    </.field>
    """
  end

  defp input_input_group(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-group-url">Website URL</.field_label>
      <.input_group>
        <.input_group_input id="input-group-url" placeholder="example.com" />
        <.input_group_addon>
          <.input_group_text>https://</.input_group_text>
        </.input_group_addon>
        <.input_group_addon align="inline-end">
          <LiveShadcn.Icon.icon name="info" />
        </.input_group_addon>
      </.input_group>
    </.field>
    """
  end

  defp input_button_group(assigns) do
    ~H"""
    <.field>
      <.field_label for="input-button-group">Search</.field_label>
      <.button_group>
        <.input id="input-button-group" placeholder="Type to search..." />
        <.button variant="outline">Search</.button>
      </.button_group>
    </.field>
    """
  end

  defp input_form(assigns) do
    ~H"""
    <form class="w-full max-w-sm">
      <.field_group>
        <.field>
          <.field_label for="form-name">Name</.field_label>
          <.input id="form-name" type="text" placeholder="Evil Rabbit" required />
        </.field>
        <.field>
          <.field_label for="form-email">Email</.field_label>
          <.input id="form-email" type="email" placeholder="john@example.com" />
          <.field_description>We'll never share your email with anyone.</.field_description>
        </.field>
        <div class="grid grid-cols-2 gap-4">
          <.field>
            <.field_label for="form-phone">Phone</.field_label>
            <.input id="form-phone" type="tel" placeholder="+1 (555) 123-4567" />
          </.field>
          <.field>
            <.field_label for="form-country">Country</.field_label>
            <.select id="form-country" trigger_id="form-country" value="us">
              <:option value="us" label="United States" />
              <:option value="uk" label="United Kingdom" />
              <:option value="ca" label="Canada" />
            </.select>
          </.field>
        </div>
        <.field>
          <.field_label for="form-address">Address</.field_label>
          <.input id="form-address" type="text" placeholder="123 Main St" />
        </.field>
        <.field orientation="horizontal">
          <.button type="button" variant="outline">Cancel</.button>
          <.button type="submit">Submit</.button>
        </.field>
      </.field_group>
    </form>
    """
  end

  defp input_rtl(assigns) do
    ~H"""
    <.field dir="rtl">
      <.field_label for="input-rtl-api-key">مفتاح API</.field_label>
      <.input id="input-rtl-api-key" type="password" placeholder="sk-..." dir="rtl" />
      <.field_description>مفتاح API الخاص بك مشفر ومخزن بأمان.</.field_description>
    </.field>
    """
  end

  defp label_default(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.checkbox id="terms" />
      <.label for="terms">Accept terms and conditions</.label>
    </div>
    """
  end

  defp label_field_demo(assigns) do
    ~H"""
    <div class="w-full max-w-md">
      <form>
        <.field_group>
          <.field_set>
            <.field_legend>Payment Method</.field_legend>
            <.field_description>All transactions are secure and encrypted</.field_description>
            <.field_group>
              <.field>
                <.field_label for="checkout-7j9-card-name-43j">Name on Card</.field_label>
                <.input id="checkout-7j9-card-name-43j" placeholder="Evil Rabbit" required />
              </.field>
              <.field>
                <.field_label for="checkout-7j9-card-number-uw1">Card Number</.field_label>
                <.input
                  id="checkout-7j9-card-number-uw1"
                  placeholder="1234 5678 9012 3456"
                  required
                />
                <.field_description>Enter your 16-digit card number</.field_description>
              </.field>
              <div class="grid grid-cols-3 gap-4">
                <.field>
                  <.field_label for="checkout-exp-month-ts6-select-trigger">Month</.field_label>
                  <.select id="checkout-exp-month-ts6-select" placeholder="MM">
                    <:option value="" label="MM" />
                    <:option
                      :for={month <- 1..12}
                      value={month |> Integer.to_string() |> String.pad_leading(2, "0")}
                    />
                  </.select>
                </.field>
                <.field>
                  <.field_label for="checkout-7j9-exp-year-f59-select-trigger">Year</.field_label>
                  <.select id="checkout-7j9-exp-year-f59-select" placeholder="YYYY">
                    <:option value="" label="YYYY" />
                    <:option :for={year <- 2024..2029} value={to_string(year)} />
                  </.select>
                </.field>
                <.field>
                  <.field_label for="checkout-7j9-cvv">CVV</.field_label>
                  <.input id="checkout-7j9-cvv" placeholder="123" required />
                </.field>
              </div>
            </.field_group>
          </.field_set>
          <.field_separator />
          <.field_set>
            <.field_legend>Billing Address</.field_legend>
            <.field_description>
              The billing address associated with your payment method
            </.field_description>
            <.field_group>
              <.field orientation="horizontal">
                <.checkbox id="checkout-7j9-same-as-shipping-wgm" checked />
                <.field_label for="checkout-7j9-same-as-shipping-wgm" class="font-normal">
                  Same as shipping address
                </.field_label>
              </.field>
            </.field_group>
          </.field_set>
          <.field_set>
            <.field_group>
              <.field>
                <.field_label for="checkout-7j9-optional-comments">Comments</.field_label>
                <.textarea
                  id="checkout-7j9-optional-comments"
                  placeholder="Add any additional comments"
                  class="resize-none"
                />
              </.field>
            </.field_group>
          </.field_set>
          <.field orientation="horizontal">
            <.button type="submit">Submit</.button>
            <.button variant="outline" type="button">Cancel</.button>
          </.field>
        </.field_group>
      </form>
    </div>
    """
  end

  defp label_rtl(assigns) do
    ~H"""
    <div class="flex gap-2" dir="rtl">
      <.checkbox id="terms-rtl" dir="rtl" />
      <.label for="terms-rtl" dir="rtl">قبول الشروط والأحكام</.label>
    </div>
    """
  end

  defp switch_default(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <.switch id="airplane-mode" />
      <.label for="airplane-mode">Airplane Mode</.label>
    </div>
    """
  end

  defp switch_description(assigns) do
    ~H"""
    <.field orientation="horizontal" class="max-w-sm">
      <.field_content>
        <.field_label for="switch-focus-mode">Share across devices</.field_label>
        <.field_description>
          Focus is shared across devices, and turns off when you leave the app.
        </.field_description>
      </.field_content>
      <.switch id="switch-focus-mode" />
    </.field>
    """
  end

  defp switch_choice_card(assigns) do
    ~H"""
    <.field_group class="w-full max-w-sm">
      <.field_label for="switch-share">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Share across devices</.field_title>
            <.field_description>
              Focus is shared across devices, and turns off when you leave the app.
            </.field_description>
          </.field_content>
          <.switch id="switch-share" />
        </.field>
      </.field_label>
      <.field_label for="switch-notifications">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Enable notifications</.field_title>
            <.field_description>
              Receive notifications when focus mode is enabled or disabled.
            </.field_description>
          </.field_content>
          <.switch id="switch-notifications" checked />
        </.field>
      </.field_label>
    </.field_group>
    """
  end

  defp switch_disabled(assigns) do
    ~H"""
    <.field orientation="horizontal" data-disabled="true" class="w-fit">
      <.switch id="switch-disabled-unchecked" disabled />
      <.field_label for="switch-disabled-unchecked">Disabled</.field_label>
    </.field>
    """
  end

  defp switch_invalid(assigns) do
    ~H"""
    <.field orientation="horizontal" class="max-w-sm" data-invalid="true">
      <.field_content>
        <.field_label for="switch-terms">Accept terms and conditions</.field_label>
        <.field_description>
          You must accept the terms and conditions to continue.
        </.field_description>
      </.field_content>
      <.switch id="switch-terms" aria-invalid="true" />
    </.field>
    """
  end

  defp switch_sizes(assigns) do
    ~H"""
    <.field_group class="w-full max-w-[10rem]">
      <.field orientation="horizontal">
        <.switch id="switch-size-sm" size="sm" />
        <.field_label for="switch-size-sm">Small</.field_label>
      </.field>
      <.field orientation="horizontal">
        <.switch id="switch-size-default" />
        <.field_label for="switch-size-default">Default</.field_label>
      </.field>
    </.field_group>
    """
  end

  defp switch_rtl(assigns) do
    ~H"""
    <.field orientation="horizontal" class="max-w-sm" dir="rtl">
      <.field_content>
        <.field_label for="switch-focus-mode-rtl" dir="rtl">المشاركة عبر الأجهزة</.field_label>
        <.field_description dir="rtl">
          يتم مشاركة التركيز عبر الأجهزة، ويتم إيقاف تشغيله عند مغادرة التطبيق.
        </.field_description>
      </.field_content>
      <.switch id="switch-focus-mode-rtl" dir="rtl" />
    </.field>
    """
  end

  defp tabs_default(assigns) do
    ~H"""
    <.tabs id="tabs-default" value="overview" class="w-[400px]">
      <:tab value="overview" label="Overview">
        <.card>
          <.card_header>
            <.card_title>Overview</.card_title>
            <.card_description>
              View your key metrics and recent project activity. Track progress across all your active projects.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            You have 12 active projects and 3 pending tasks.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="analytics" label="Analytics">
        <.card>
          <.card_header>
            <.card_title>Analytics</.card_title>
            <.card_description>
              Track performance and user engagement metrics. Monitor trends and identify growth opportunities.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            Page views are up 25% compared to last month.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="reports" label="Reports">
        <.card>
          <.card_header>
            <.card_title>Reports</.card_title>
            <.card_description>
              Generate and download your detailed reports. Export data in multiple formats for analysis.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            You have 5 reports ready and available to export.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="settings" label="Settings">
        <.card>
          <.card_header>
            <.card_title>Settings</.card_title>
            <.card_description>
              Manage your account preferences and options. Customize your experience to fit your needs.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            Configure notifications, security, and themes.
          </.card_content>
        </.card>
      </:tab>
    </.tabs>
    """
  end

  defp tabs_line(assigns) do
    ~H"""
    <.tabs id="tabs-line" value="overview" variant="line">
      <:tab value="overview" label="Overview" panel={false} />
      <:tab value="analytics" label="Analytics" panel={false} />
      <:tab value="reports" label="Reports" panel={false} />
    </.tabs>
    """
  end

  defp tabs_vertical(assigns) do
    ~H"""
    <.tabs id="tabs-vertical" value="account" orientation="vertical">
      <:tab value="account" label="Account" panel={false} />
      <:tab value="password" label="Password" panel={false} />
      <:tab value="notifications" label="Notifications" panel={false} />
    </.tabs>
    """
  end

  defp tabs_disabled(assigns) do
    ~H"""
    <.tabs id="tabs-disabled" value="home">
      <:tab value="home" label="Home" panel={false} />
      <:tab value="settings" label="Disabled" disabled panel={false} />
    </.tabs>
    """
  end

  defp tabs_icons(assigns) do
    ~H"""
    <.tabs id="tabs-icons" value="preview">
      <:tab value="preview" label="Preview" icon="app-window" panel={false} />
      <:tab value="code" label="Code" icon="code" panel={false} />
    </.tabs>
    """
  end

  defp tabs_rtl(assigns) do
    ~H"""
    <.tabs id="tabs-rtl" value="overview" class="w-full max-w-sm" dir="rtl">
      <:tab value="overview" label="نظرة عامة">
        <.card dir="rtl">
          <.card_header>
            <.card_title>نظرة عامة</.card_title>
            <.card_description>
              عرض مقاييسك الرئيسية وأنشطة المشروع الأخيرة. تتبع التقدم عبر جميع مشاريعك النشطة.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            لديك ١٢ مشروعًا نشطًا و٣ مهام معلقة.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="analytics" label="التحليلات">
        <.card dir="rtl">
          <.card_header>
            <.card_title>التحليلات</.card_title>
            <.card_description>
              تتبع مقاييس الأداء ومشاركة المستخدمين. راقب الاتجاهات وحدد فرص النمو.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            زادت مشاهدات الصفحة بنسبة ٢٥٪ مقارنة بالشهر الماضي.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="reports" label="التقارير">
        <.card dir="rtl">
          <.card_header>
            <.card_title>التقارير</.card_title>
            <.card_description>
              إنشاء وتنزيل تقاريرك التفصيلية. تصدير البيانات بتنسيقات متعددة للتحليل.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            لديك ٥ تقارير جاهزة ومتاحة للتصدير.
          </.card_content>
        </.card>
      </:tab>
      <:tab value="settings" label="الإعدادات">
        <.card dir="rtl">
          <.card_header>
            <.card_title>الإعدادات</.card_title>
            <.card_description>
              إدارة تفضيلات حسابك وخياراته. تخصيص تجربتك لتناسب احتياجاتك.
            </.card_description>
          </.card_header>
          <.card_content class="text-sm text-muted-foreground">
            تكوين الإشعارات والأمان والسمات.
          </.card_content>
        </.card>
      </:tab>
    </.tabs>
    """
  end

  defp textarea_default(assigns) do
    ~H"""
    <.textarea placeholder="Type your message here." />
    """
  end

  defp textarea_field(assigns) do
    ~H"""
    <.field>
      <.field_label for="textarea-message">Message</.field_label>
      <.field_description>Enter your message below.</.field_description>
      <.textarea id="textarea-message" placeholder="Type your message here." />
    </.field>
    """
  end

  defp textarea_disabled(assigns) do
    ~H"""
    <.field data-disabled="true">
      <.field_label for="textarea-disabled">Message</.field_label>
      <.textarea id="textarea-disabled" placeholder="Type your message here." disabled />
    </.field>
    """
  end

  defp textarea_invalid(assigns) do
    ~H"""
    <.field data-invalid="true">
      <.field_label for="textarea-invalid">Message</.field_label>
      <.textarea id="textarea-invalid" placeholder="Type your message here." aria-invalid="true" />
      <.field_description>Please enter a valid message.</.field_description>
    </.field>
    """
  end

  defp textarea_button(assigns) do
    ~H"""
    <div class="grid w-full gap-2">
      <.textarea placeholder="Type your message here." />
      <.button>Send message</.button>
    </div>
    """
  end

  defp textarea_rtl(assigns) do
    ~H"""
    <.field class="w-full max-w-xs" dir="rtl">
      <.field_label for="feedback" dir="rtl">التعليقات</.field_label>
      <.textarea
        id="feedback"
        placeholder="تعليقاتك تساعدنا على التحسين..."
        dir="rtl"
        rows="4"
      />
      <.field_description dir="rtl">شاركنا أفكارك حول خدمتنا.</.field_description>
    </.field>
    """
  end

  defp toggle_default(assigns) do
    ~H"""
    <.toggle id="bookmark" aria-label="Toggle bookmark" size="sm" variant="outline">
      <LiveShadcn.Icon.icon name="bookmark" class="group-aria-pressed/toggle:fill-foreground" />
      Bookmark
    </.toggle>
    """
  end

  defp toggle_outline(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.toggle id="italic-outline" variant="outline" aria-label="Toggle italic">
        <LiveShadcn.Icon.icon name="italic" /> Italic
      </.toggle>
      <.toggle id="bold-outline" variant="outline" aria-label="Toggle bold">
        <LiveShadcn.Icon.icon name="bold" /> Bold
      </.toggle>
    </div>
    """
  end

  defp toggle_text(assigns) do
    ~H"""
    <.toggle id="italic-text" aria-label="Toggle italic">
      <LiveShadcn.Icon.icon name="italic" /> Italic
    </.toggle>
    """
  end

  defp toggle_sizes(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.toggle id="toggle-small" variant="outline" aria-label="Toggle small" size="sm">
        Small
      </.toggle>
      <.toggle id="toggle-default" variant="outline" aria-label="Toggle default">
        Default
      </.toggle>
      <.toggle id="toggle-large" variant="outline" aria-label="Toggle large" size="lg">
        Large
      </.toggle>
    </div>
    """
  end

  defp toggle_disabled(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2">
      <.toggle id="toggle-disabled" aria-label="Toggle disabled" disabled>Disabled</.toggle>
      <.toggle
        id="toggle-disabled-outline"
        variant="outline"
        aria-label="Toggle disabled outline"
        disabled
      >
        Disabled
      </.toggle>
    </div>
    """
  end

  defp toggle_rtl(assigns) do
    ~H"""
    <.toggle
      id="bookmark-rtl"
      aria-label="Toggle bookmark"
      size="sm"
      variant="outline"
      dir="rtl"
    >
      <LiveShadcn.Icon.icon name="bookmark" class="group-aria-pressed/toggle:fill-foreground" />
      إشارة مرجعية
    </.toggle>
    """
  end

  defp toggle_group_default(assigns) do
    ~H"""
    <.toggle_group id="format" variant="outline" multiple>
      <:item value="bold" aria-label="Toggle bold"><LiveShadcn.Icon.icon name="bold" /></:item>
      <:item value="italic" aria-label="Toggle italic"><LiveShadcn.Icon.icon name="italic" /></:item>
      <:item value="strikethrough" aria-label="Toggle strikethrough">
        <LiveShadcn.Icon.icon name="underline" />
      </:item>
    </.toggle_group>
    """
  end

  defp toggle_group_outline(assigns) do
    ~H"""
    <.toggle_group id="outline-group" variant="outline">
      <:item value="all" aria-label="Toggle all" checked>All</:item>
      <:item value="missed" aria-label="Toggle missed">Missed</:item>
    </.toggle_group>
    """
  end

  defp toggle_group_sizes(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.toggle_group id="size-small" size="sm" variant="outline">
        <:item value="top" aria-label="Toggle top" checked>Top</:item>
        <:item value="bottom" aria-label="Toggle bottom">Bottom</:item>
        <:item value="left" aria-label="Toggle left">Left</:item>
        <:item value="right" aria-label="Toggle right">Right</:item>
      </.toggle_group>
      <.toggle_group id="size-default" variant="outline">
        <:item value="top" aria-label="Toggle top" checked>Top</:item>
        <:item value="bottom" aria-label="Toggle bottom">Bottom</:item>
        <:item value="left" aria-label="Toggle left">Left</:item>
        <:item value="right" aria-label="Toggle right">Right</:item>
      </.toggle_group>
    </div>
    """
  end

  defp toggle_group_spacing(assigns) do
    ~H"""
    <.toggle_group id="spacing-group" size="sm" variant="outline" spacing={2}>
      <:item value="top" aria-label="Toggle top" checked>Top</:item>
      <:item value="bottom" aria-label="Toggle bottom">Bottom</:item>
      <:item value="left" aria-label="Toggle left">Left</:item>
      <:item value="right" aria-label="Toggle right">Right</:item>
    </.toggle_group>
    """
  end

  defp toggle_group_vertical(assigns) do
    ~H"""
    <.toggle_group id="vertical-group" multiple orientation="vertical" spacing={1}>
      <:item value="bold" aria-label="Toggle bold" checked>
        <LiveShadcn.Icon.icon name="bold" />
      </:item>
      <:item value="italic" aria-label="Toggle italic" checked>
        <LiveShadcn.Icon.icon name="italic" />
      </:item>
      <:item value="underline" aria-label="Toggle underline">
        <LiveShadcn.Icon.icon name="underline" />
      </:item>
    </.toggle_group>
    """
  end

  defp toggle_group_disabled(assigns) do
    ~H"""
    <.toggle_group id="disabled-group" disabled>
      <:item value="bold" aria-label="Toggle bold"><LiveShadcn.Icon.icon name="bold" /></:item>
      <:item value="italic" aria-label="Toggle italic"><LiveShadcn.Icon.icon name="italic" /></:item>
      <:item value="strikethrough" aria-label="Toggle strikethrough">
        <LiveShadcn.Icon.icon name="underline" />
      </:item>
    </.toggle_group>
    """
  end

  defp toggle_group_font_weight_selector(assigns) do
    ~H"""
    <.field>
      <.field_label>Font Weight</.field_label>
      <.toggle_group
        id="font-weight-group"
        variant="outline"
        spacing={2}
        size="lg"
        output="#font-weight-output"
        output_prefix="font-"
      >
        <:item
          value="light"
          aria-label="Light"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-light">Aa</span>
          <span class="text-xs text-muted-foreground">Light</span>
        </:item>
        <:item
          value="normal"
          aria-label="Normal"
          checked
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-normal">Aa</span>
          <span class="text-xs text-muted-foreground">Normal</span>
        </:item>
        <:item
          value="medium"
          aria-label="Medium"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-medium">Aa</span>
          <span class="text-xs text-muted-foreground">Medium</span>
        </:item>
        <:item
          value="bold"
          aria-label="Bold"
          class="flex size-16 flex-col items-center justify-center rounded-xl"
        >
          <span class="text-2xl leading-none font-bold">Aa</span>
          <span class="text-xs text-muted-foreground">Bold</span>
        </:item>
      </.toggle_group>
      <.field_description>
        Use
        <code id="font-weight-output" class="rounded-md bg-muted px-1 py-0.5 font-mono">font-normal</code>
        to set the font weight.
      </.field_description>
    </.field>
    """
  end

  defp toggle_group_rtl(assigns) do
    ~H"""
    <.toggle_group id="view-group-rtl" variant="outline" dir="rtl">
      <:item value="list" aria-label="قائمة" checked>قائمة</:item>
      <:item value="grid" aria-label="شبكة">شبكة</:item>
      <:item value="cards" aria-label="بطاقات">بطاقات</:item>
    </.toggle_group>
    """
  end

  defp card_default(assigns) do
    ~H"""
    <.card class="w-full max-w-sm">
      <.card_header>
        <.card_title>Login to your account</.card_title>
        <.card_description>Enter your email below to login to your account</.card_description>
        <.card_action><.button variant="link">Sign Up</.button></.card_action>
      </.card_header>
      <.card_content>
        <form>
          <div class="flex flex-col gap-6">
            <div class="grid gap-2">
              <.label for="email">Email</.label>
              <.input id="email" type="email" placeholder="m@example.com" required />
            </div>
            <div class="grid gap-2">
              <div class="flex items-center">
                <.label for="password">Password</.label>
                <a href="#" class="ml-auto inline-block text-sm underline-offset-4 hover:underline">
                  Forgot your password?
                </a>
              </div>
              <.input id="password" type="password" required />
            </div>
          </div>
        </form>
      </.card_content>
      <.card_footer class="flex-col gap-2">
        <.button type="submit" class="w-full">Login</.button>
        <.button variant="outline" class="w-full">Login with Google</.button>
      </.card_footer>
    </.card>
    """
  end

  defp card_small(assigns) do
    ~H"""
    <.card size="sm" class="mx-auto w-full max-w-xs">
      <.card_header>
        <.card_title>Scheduled reports</.card_title>
        <.card_description>Weekly snapshots. No more manual exports.</.card_description>
      </.card_header>
      <.card_content>
        <ul class="grid gap-2 py-2 text-sm">
          <li class="flex gap-2">
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class="mt-0.5 size-4 shrink-0 text-muted-foreground"
            />
            <span>Choose a schedule (daily, or weekly).</span>
          </li>
          <li class="flex gap-2">
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class="mt-0.5 size-4 shrink-0 text-muted-foreground"
            />
            <span>Send to channels or specific teammates.</span>
          </li>
          <li class="flex gap-2">
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class="mt-0.5 size-4 shrink-0 text-muted-foreground"
            />
            <span>Include charts, tables, and key metrics.</span>
          </li>
        </ul>
      </.card_content>
      <.card_footer class="flex-col gap-2">
        <.button size="sm" class="w-full">Set up scheduled reports</.button>
        <.button variant="outline" size="sm" class="w-full">See what's new</.button>
      </.card_footer>
    </.card>
    """
  end

  defp card_spacing(assigns) do
    ~H"""
    <div class="mx-auto grid w-full max-w-sm gap-4">
      <.toggle_group id="progress-presets" variant="outline" size="sm" class="justify-center">
        <:item
          :for={{value, label} <- [{"4", "16px"}, {"5", "20px"}, {"6", "24px"}, {"8", "32px"}]}
          id={"card-spacing-#{value}"}
          value={value}
          checked={@card_spacing == value}
          on_click={JS.push("card_spacing", value: %{spacing: value})}
        >
          {label}
        </:item>
      </.toggle_group>
      <.card class={card_spacing_class(@card_spacing)}>
        <.card_header>
          <.card_title>Login to your account</.card_title>
          <.card_description>Enter your email below to login to your account</.card_description>
          <.card_action><.button variant="link">Sign Up</.button></.card_action>
        </.card_header>
        <.card_content>
          <form>
            <div class="flex flex-col gap-6">
              <div class="grid gap-2">
                <.label for="email-spacing">Email</.label>
                <.input id="email-spacing" type="email" placeholder="m@example.com" required />
              </div>
              <div class="grid gap-2">
                <div class="flex items-center">
                  <.label for="password-spacing">Password</.label>
                  <a href="#" class="ml-auto inline-block text-sm underline-offset-4 hover:underline">
                    Forgot your password?
                  </a>
                </div>
                <.input id="password-spacing" type="password" required />
              </div>
            </div>
          </form>
        </.card_content>
        <.card_footer class="flex-col gap-2">
          <.button type="submit" class="w-full">Login</.button>
          <.button variant="outline" class="w-full">Login with Google</.button>
        </.card_footer>
      </.card>
    </div>
    """
  end

  defp card_edge_to_edge(assigns) do
    ~H"""
    <.card class="mx-auto w-full max-w-sm">
      <.card_header>
        <.card_title>Terms of Service</.card_title>
        <.card_description>Review the terms before accepting the agreement.</.card_description>
      </.card_header>
      <.card_content class="-mb-(--card-spacing)">
        <div class="-mx-(--card-spacing) max-h-48 space-y-4 overflow-y-scroll border-t bg-muted/50 px-(--card-spacing) py-4 text-sm leading-relaxed">
          <p>
            These terms govern your use of the workspace, including access to shared documents,
            project files, and collaboration tools.
          </p>
          <p>
            You are responsible for the content you upload and for ensuring that your team has
            the appropriate permissions to view or edit it.
          </p>
          <p>
            We may update features or limits as the service evolves. When those changes materially
            affect your workflow, we will notify your workspace administrators.
          </p>
          <p>
            By continuing, you agree to keep your account credentials secure and to follow your
            organization's acceptable use policies.
          </p>
        </div>
      </.card_content>
      <.card_footer class="justify-end gap-2">
        <.button variant="outline">Decline</.button>
        <.button>Accept</.button>
      </.card_footer>
    </.card>
    """
  end

  defp card_image(assigns) do
    ~H"""
    <.card class="relative mx-auto w-full max-w-sm pt-0">
      <div class="absolute inset-0 z-30 aspect-video bg-black/35"></div>
      <img
        src="https://avatar.vercel.sh/shadcn1"
        alt="Event cover"
        class="relative z-20 aspect-video w-full object-cover brightness-60 grayscale dark:brightness-40"
      />
      <.card_header>
        <.card_action>
          <.badge variant="secondary">Featured</.badge>
        </.card_action>
        <.card_title>Design systems meetup</.card_title>
        <.card_description>
          A practical talk on component APIs, accessibility, and shipping faster.
        </.card_description>
      </.card_header>
      <.card_footer><.button class="w-full">View Event</.button></.card_footer>
    </.card>
    """
  end

  defp card_rtl(assigns) do
    ~H"""
    <.card class="w-full max-w-sm" dir="rtl">
      <.card_header>
        <.card_title>تسجيل الدخول إلى حسابك</.card_title>
        <.card_description>أدخل بريدك الإلكتروني أدناه لتسجيل الدخول إلى حسابك</.card_description>
        <.card_action><.button variant="link">إنشاء حساب</.button></.card_action>
      </.card_header>
      <.card_content>
        <form>
          <div class="flex flex-col gap-6">
            <div class="grid gap-2">
              <.label for="email-rtl">البريد الإلكتروني</.label>
              <.input id="email-rtl" type="email" placeholder="m@example.com" required />
            </div>
            <div class="grid gap-2">
              <div class="flex items-center">
                <.label for="password-rtl">كلمة المرور</.label>
                <a href="#" class="ms-auto inline-block text-sm underline-offset-4 hover:underline">
                  نسيت كلمة المرور؟
                </a>
              </div>
              <.input id="password-rtl" type="password" required />
            </div>
          </div>
        </form>
      </.card_content>
      <.card_footer class="flex-col gap-2">
        <.button type="submit" class="w-full">تسجيل الدخول</.button>
        <.button variant="outline" class="w-full">تسجيل الدخول باستخدام Google</.button>
      </.card_footer>
    </.card>
    """
  end

  defp collapsible_default(assigns) do
    ~H"""
    <.collapsible id="collapsible-default" composed class="flex w-[350px] flex-col gap-2">
      <div class="flex items-center justify-between gap-4 px-4">
        <h4 class="text-sm font-semibold">Order #4189</h4>
        <.collapsible_trigger
          for="collapsible-default"
          class={collapsible_button_class("ghost", "icon", "size-8")}
        >
          <LiveShadcn.Icon.icon name="chevrons-up-down" />
          <span class="sr-only">Toggle details</span>
        </.collapsible_trigger>
      </div>
      <div class="flex items-center justify-between rounded-md border px-4 py-2 text-sm">
        <span class="text-muted-foreground">Status</span>
        <span class="font-medium">Shipped</span>
      </div>
      <.collapsible_content for="collapsible-default" class="flex flex-col gap-2">
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">Shipping address</p>
          <p class="text-muted-foreground">100 Market St, San Francisco</p>
        </div>
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">Items</p>
          <p class="text-muted-foreground">2x Studio Headphones</p>
        </div>
      </.collapsible_content>
    </.collapsible>
    """
  end

  defp collapsible_basic(assigns) do
    ~H"""
    <.card class="mx-auto w-full max-w-sm">
      <.card_content>
        <.collapsible
          id="collapsible-basic"
          composed
          class="rounded-md data-open:bg-muted"
        >
          <.collapsible_trigger
            for="collapsible-basic"
            class={collapsible_button_class("ghost", "default", "w-full")}
          >
            Product details
            <LiveShadcn.Icon.icon
              name="chevron-down"
              class="ml-auto group-data-panel-open/button:rotate-180"
            />
          </.collapsible_trigger>
          <.collapsible_content
            for="collapsible-basic"
            class="flex flex-col items-start gap-2 p-2.5 pt-0 text-sm"
          >
            <div>This panel can be expanded or collapsed to reveal additional content.</div>
            <.button size="xs">Learn More</.button>
          </.collapsible_content>
        </.collapsible>
      </.card_content>
    </.card>
    """
  end

  defp collapsible_settings(assigns) do
    ~H"""
    <.card class="mx-auto w-full max-w-xs" size="sm">
      <.card_header>
        <.card_title>Radius</.card_title>
        <.card_description>Set the corner radius of the element.</.card_description>
      </.card_header>
      <.card_content>
        <.collapsible
          id="collapsible-settings"
          composed
          class="flex items-start gap-2"
        >
          <.field_group class="grid w-full grid-cols-2 gap-2">
            <.field>
              <.field_label for="radius-x" class="sr-only">Radius X</.field_label>
              <.input id="radius-x" placeholder="0" value="0" />
            </.field>
            <.field>
              <.field_label for="radius-y" class="sr-only">Radius Y</.field_label>
              <.input id="radius-y" placeholder="0" value="0" />
            </.field>
            <.collapsible_content
              for="collapsible-settings"
              class="col-span-full grid grid-cols-subgrid gap-2"
            >
              <.field>
                <.field_label for="radius-x-expanded" class="sr-only">Radius X</.field_label>
                <.input id="radius-x-expanded" placeholder="0" value="0" />
              </.field>
              <.field>
                <.field_label for="radius-y-expanded" class="sr-only">Radius Y</.field_label>
                <.input id="radius-y-expanded" placeholder="0" value="0" />
              </.field>
            </.collapsible_content>
          </.field_group>
          <.collapsible_trigger
            for="collapsible-settings"
            class={collapsible_button_class("outline", "icon")}
          >
            <LiveShadcn.Icon.icon
              name="maximize"
              class="group-data-panel-open/button:hidden"
            />
            <LiveShadcn.Icon.icon
              name="minimize"
              class="hidden group-data-panel-open/button:block"
            />
          </.collapsible_trigger>
        </.collapsible>
      </.card_content>
    </.card>
    """
  end

  defp collapsible_file_tree(assigns) do
    assigns = assign(assigns, :file_tree, @collapsible_file_tree)

    ~H"""
    <.card class="mx-auto w-full max-w-[16rem] gap-2" size="sm">
      <.card_header>
        <.tabs id="collapsible-file-tabs" value="explorer" list_class="w-full">
          <:tab value="explorer" label="Explorer" panel={false} />
          <:tab value="settings" label="Outline" panel={false} />
        </.tabs>
      </.card_header>
      <.card_content>
        <div class="flex flex-col gap-1">
          <.collapsible_file_items items={@file_tree} path="root" />
        </div>
      </.card_content>
    </.card>
    """
  end

  attr(:items, :list, required: true)
  attr(:path, :string, required: true)

  defp collapsible_file_items(assigns) do
    ~H"""
    <%= for item <- @items do %>
      <%= if Map.has_key?(item, :items) do %>
        <.collapsible
          id={collapsible_tree_id(@path, item.name)}
          composed
        >
          <.collapsible_trigger
            for={collapsible_tree_id(@path, item.name)}
            class={
              collapsible_button_class(
                "ghost",
                "sm",
                "group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
              )
            }
          >
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class="transition-transform group-data-[state=open]:rotate-90"
            />
            <LiveShadcn.Icon.icon name="folder" />
            {item.name}
          </.collapsible_trigger>
          <.collapsible_content
            for={collapsible_tree_id(@path, item.name)}
            class="mt-1 ml-5 style-lyra:ml-4"
          >
            <div class="flex flex-col gap-1">
              <.collapsible_file_items
                items={item.items}
                path={@path <> "-" <> item.name}
              />
            </div>
          </.collapsible_content>
        </.collapsible>
      <% else %>
        <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
          <LiveShadcn.Icon.icon name="file" />
          <span>{item.name}</span>
        </.button>
      <% end %>
    <% end %>
    """
  end

  defp collapsible_rtl(assigns) do
    ~H"""
    <.collapsible
      id="collapsible-rtl"
      composed
      dir="rtl"
      class="flex w-[350px] flex-col gap-2"
    >
      <div class="flex items-center justify-between gap-4 px-4">
        <h4 class="text-sm font-semibold">الطلب #4189</h4>
        <.collapsible_trigger
          for="collapsible-rtl"
          class={collapsible_button_class("ghost", "icon", "size-8")}
        >
          <LiveShadcn.Icon.icon name="chevrons-up-down" />
          <span class="sr-only">Toggle details</span>
        </.collapsible_trigger>
      </div>
      <div class="flex items-center justify-between rounded-md border px-4 py-2 text-sm">
        <span class="text-muted-foreground">الحالة</span>
        <span class="font-medium">تم الشحن</span>
      </div>
      <.collapsible_content for="collapsible-rtl" class="flex flex-col gap-2">
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">عنوان الشحن</p>
          <p class="text-muted-foreground">100 Market St, San Francisco</p>
        </div>
        <div class="rounded-md border px-4 py-2 text-sm">
          <p class="font-medium">العناصر</p>
          <p class="text-muted-foreground">2x سماعات الاستوديو</p>
        </div>
      </.collapsible_content>
    </.collapsible>
    """
  end

  defp collapsible_button_class(variant, size, class \\ nil) do
    LiveShadcn.Cn.merge([
      LiveShadcn.UI.Button.part_class("button"),
      LiveShadcn.UI.Button.variant_class("buttonVariants", "variant", variant),
      LiveShadcn.UI.Button.variant_class("buttonVariants", "size", size),
      class
    ])
  end

  defp collapsible_tree_id(path, name) do
    slug =
      [path, name]
      |> Enum.join("-")
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    "collapsible-tree-#{slug}"
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
    <div class="w-full max-w-2xl">
      <.confirmation approval={%{id: "confirmation-default"}} state="approval-requested">
        <.confirmation_title>
          <.confirmation_request state="approval-requested">
            This tool wants to delete the file <code class="inline rounded bg-muted px-1.5 py-0.5 text-sm">/tmp/example.txt</code>. Do you approve this action?
          </.confirmation_request>
          <.confirmation_accepted approval={%{id: "confirmation-default"}} state="approval-requested">
            <LiveShadcn.Icon.icon name="check" class="size-4 text-green-600 dark:text-green-400" />
            <span>You approved this tool execution</span>
          </.confirmation_accepted>
          <.confirmation_rejected approval={%{id: "confirmation-default"}} state="approval-requested">
            <LiveShadcn.Icon.icon name="x" class="size-4 text-destructive" />
            <span>You rejected this tool execution</span>
          </.confirmation_rejected>
        </.confirmation_title>
        <.confirmation_actions state="approval-requested">
          <.confirmation_action variant="outline">Reject</.confirmation_action>
          <.confirmation_action variant="default">Approve</.confirmation_action>
        </.confirmation_actions>
      </.confirmation>
    </div>
    """
  end

  defp confirmation_request_example(assigns) do
    ~H"""
    <div class="w-full max-w-2xl">
      <.confirmation approval={%{id: "confirmation-request"}} state="approval-requested">
        <.confirmation_title>
          <.confirmation_request state="approval-requested">
            This tool wants to execute a query on the production database:
            <code class="mt-2 block rounded bg-muted p-2 text-sm">SELECT * FROM users WHERE role = 'admin'</code>
          </.confirmation_request>
          <.confirmation_accepted approval={%{id: "confirmation-request"}} state="approval-requested">
            <LiveShadcn.Icon.icon name="check" class="size-4 text-green-600 dark:text-green-400" />
            <span>You approved this tool execution</span>
          </.confirmation_accepted>
          <.confirmation_rejected approval={%{id: "confirmation-request"}} state="approval-requested">
            <LiveShadcn.Icon.icon name="x" class="size-4 text-destructive" />
            <span>You rejected this tool execution</span>
          </.confirmation_rejected>
        </.confirmation_title>
        <.confirmation_actions state="approval-requested">
          <.confirmation_action variant="outline">Reject</.confirmation_action>
          <.confirmation_action variant="default">Approve</.confirmation_action>
        </.confirmation_actions>
      </.confirmation>
    </div>
    """
  end

  defp confirmation_accepted_example(assigns) do
    ~H"""
    <div class="w-full max-w-2xl">
      <.confirmation
        approval={%{id: "confirmation-accepted", approved: true}}
        state="approval-responded"
      >
        <.confirmation_title>
          <.confirmation_request state="approval-responded">
            This tool wants to delete the file <code class="rounded bg-muted px-1.5 py-0.5 text-sm">/tmp/example.txt</code>. Do you approve this action?
          </.confirmation_request>
          <.confirmation_accepted
            approval={%{id: "confirmation-accepted", approved: true}}
            state="approval-responded"
          >
            <LiveShadcn.Icon.icon name="check" class="size-4 text-green-600 dark:text-green-400" />
            <span>You approved this tool execution</span>
          </.confirmation_accepted>
          <.confirmation_rejected
            approval={%{id: "confirmation-accepted", approved: true}}
            state="approval-responded"
          >
            <LiveShadcn.Icon.icon name="x" class="size-4 text-destructive" />
            <span>You rejected this tool execution</span>
          </.confirmation_rejected>
        </.confirmation_title>
      </.confirmation>
    </div>
    """
  end

  defp confirmation_rejected_example(assigns) do
    ~H"""
    <div class="w-full max-w-2xl">
      <.confirmation approval={%{id: "confirmation-rejected", approved: false}} state="output-denied">
        <.confirmation_title>
          <.confirmation_request state="output-denied">
            This tool wants to delete the file <code class="rounded bg-muted px-1.5 py-0.5 text-sm">/tmp/example.txt</code>. Do you approve this action?
          </.confirmation_request>
          <.confirmation_accepted
            approval={%{id: "confirmation-rejected", approved: false}}
            state="output-denied"
          >
            <LiveShadcn.Icon.icon name="check" class="size-4 text-green-600 dark:text-green-400" />
            <span>You approved this tool execution</span>
          </.confirmation_accepted>
          <.confirmation_rejected
            approval={%{id: "confirmation-rejected", approved: false}}
            state="output-denied"
          >
            <LiveShadcn.Icon.icon name="x" class="size-4 text-destructive" />
            <span>You rejected this tool execution</span>
          </.confirmation_rejected>
        </.confirmation_title>
      </.confirmation>
    </div>
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

  defp attachments_default(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-8">
      <AiAttachments.attachments :let={attachments} variant="grid">
        <AiAttachments.attachment
          :for={attachment <- @attachment_examples["default"]}
          data={attachment}
          variant={attachments.variant}
          on_remove={
            Phoenix.LiveView.JS.push("remove_attachment",
              value: %{example: "default", id: attachment.id}
            )
          }
        />
      </AiAttachments.attachments>
    </div>
    """
  end

  defp attachments_list(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-8">
      <AiAttachments.attachments :let={attachments} variant="list" class="w-full max-w-md">
        <AiAttachments.attachment
          :for={attachment <- @attachment_examples["list"]}
          data={attachment}
          variant={attachments.variant}
          on_remove={
            Phoenix.LiveView.JS.push("remove_attachment",
              value: %{example: "list", id: attachment.id}
            )
          }
        />
      </AiAttachments.attachments>
    </div>
    """
  end

  defp attachments_inline(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-8">
      <AiAttachments.attachments :let={attachments} variant="inline">
        <AiAttachments.attachment_hover_card
          :let={hover_card}
          :for={attachment <- @attachment_examples["inline"]}
          id={"attachment-inline-#{attachment.id}"}
        >
          <AiAttachments.attachment_hover_card_trigger
            :let={trigger}
            id={hover_card.id}
            open={hover_card.open}
            disabled={hover_card.disabled}
            delay={hover_card.delay}
            close_delay={hover_card.close_delay}
            variant={hover_card.trigger_variant}
            size={hover_card.trigger_size}
            as={hover_card.trigger_as}
            as_child
            class={hover_card.trigger_class}
          >
            <AiAttachments.attachment
              data={attachment}
              variant={attachments.variant}
              hover_card={trigger}
              on_remove={
                Phoenix.LiveView.JS.push("remove_attachment",
                  value: %{example: "inline", id: attachment.id}
                )
              }
            />
          </AiAttachments.attachment_hover_card_trigger>
          <AiAttachments.attachment_hover_card_content
            id={hover_card.id}
            open={hover_card.open}
            side={hover_card.side}
            align={hover_card.align}
            offset={hover_card.offset}
            autofocus={hover_card.autofocus}
            dir={hover_card.dir}
            align_offset={hover_card.align_offset}
          >
            <div class="space-y-3">
              <div
                :if={
                  String.starts_with?(Map.get(attachment, :mediaType, ""), "image/") and
                    Map.get(attachment, :url)
                }
                class="flex max-h-96 w-80 items-center justify-center overflow-hidden rounded-md border"
              >
                <img
                  alt={Map.get(attachment, :filename, "Image")}
                  class="max-h-full max-w-full object-contain"
                  height="384"
                  src={Map.get(attachment, :url)}
                  width="320"
                />
              </div>
              <div class="space-y-1 px-0.5">
                <h4 class="font-semibold text-sm leading-none">
                  {Map.get(attachment, :title) || Map.get(attachment, :filename) || "Source"}
                </h4>
                <p
                  :if={Map.get(attachment, :mediaType)}
                  class="font-mono text-muted-foreground text-xs"
                >
                  {Map.get(attachment, :mediaType)}
                </p>
              </div>
            </div>
          </AiAttachments.attachment_hover_card_content>
        </AiAttachments.attachment_hover_card>
      </AiAttachments.attachments>
    </div>
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
    <.drawer id="drawer-demo" swipe_direction="right">
      <:trigger>Open Drawer</:trigger>
      <:title>Pick a delivery time</:title>
      <:description>We'll prepare your order as soon as possible.</:description>
      <div class="flex-1 scroll-fade overflow-y-auto p-4">
        <.radio_group id="drawer-delivery-times" class="gap-2">
          <.field_label for="delivery-asap">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title class="flex items-center gap-2">
                  Standard delivery
                  <.badge variant="secondary">Fastest</.badge>
                </.field_title>
                <.field_description>25–35 min · Driver assigned now</.field_description>
              </.field_content>
              <.radio_group_item
                id="delivery-asap"
                group="drawer-delivery-times"
                value="asap"
                checked
              />
            </.field>
          </.field_label>
          <.field_label for="delivery-5-00">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>5:00 PM – 5:15 PM</.field_title>
                <.field_description>Prep starts at 4:45 PM</.field_description>
              </.field_content>
              <.radio_group_item
                id="delivery-5-00"
                group="drawer-delivery-times"
                value="5-00"
              />
            </.field>
          </.field_label>
          <.field_label for="delivery-5-30">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>5:30 PM – 5:45 PM</.field_title>
                <.field_description>Good if you're heading home</.field_description>
              </.field_content>
              <.radio_group_item
                id="delivery-5-30"
                group="drawer-delivery-times"
                value="5-30"
              />
            </.field>
          </.field_label>
          <.field_label for="delivery-6-00">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>6:00 PM – 6:15 PM</.field_title>
                <.field_description>Most popular · High demand</.field_description>
              </.field_content>
              <.radio_group_item
                id="delivery-6-00"
                group="drawer-delivery-times"
                value="6-00"
              />
            </.field>
          </.field_label>
          <.field_label for="delivery-6-30">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>6:30 PM – 6:45 PM</.field_title>
                <.field_description>Last slot before kitchen closes</.field_description>
              </.field_content>
              <.radio_group_item
                id="delivery-6-30"
                group="drawer-delivery-times"
                value="6-30"
              />
            </.field>
          </.field_label>
        </.radio_group>
      </div>
      <:footer>
        <.button
          class="h-[34px]"
          phx-click={LiveBase.Dialog.close("drawer-demo")}
        >
          Confirm Delivery Time
        </.button>
      </:footer>
      <:close variant="outline">Cancel</:close>
    </.drawer>
    """
  end

  defp drawer_sides(assigns) do
    ~H"""
    <.drawer id="drawer-sides" swipe_direction="left">
      <:trigger>Open Left Drawer</:trigger>
      <:title>Move Goal</:title>
      <:description>Set your daily activity goal.</:description>
      <div class="flex-1 p-4">
        <div class="size-full rounded-2xl bg-muted" />
      </div>
      <:close>Close</:close>
    </.drawer>
    """
  end

  defp drawer_swipe_handle(assigns) do
    ~H"""
    <.drawer id="drawer-swipe-handle" show_swipe_handle>
      <:trigger>Open Drawer</:trigger>
      <:title>Drawer</:title>
      <:description>Drawer with a swipe handle.</:description>
      <div class="flex-1 p-4">
        <div class="rounded-2xl bg-muted group-data-[swipe-axis=x]/drawer-popup:size-full group-data-[swipe-axis=y]/drawer-popup:h-80 group-data-[swipe-axis=y]/drawer-popup:w-full" />
      </div>
      <:close>Close</:close>
    </.drawer>
    """
  end

  defp drawer_nested(assigns) do
    ~H"""
    <.drawer id="drawer-nested" swipe_direction="right">
      <:trigger>Open Drawer</:trigger>
      <:title>Drawer</:title>
      <:description>Open another drawer from the same direction.</:description>
      <.drawer_placeholder />
      <:footer>
        <.drawer
          id="drawer-nested-2"
          nested
          parent="drawer-nested"
          swipe_direction="right"
          trigger_variant="outline"
        >
          <:trigger>Open Nested Drawer</:trigger>
          <:title>Nested Drawer</:title>
          <:description>The parent drawer stays mounted behind this one.</:description>
          <.drawer_placeholder />
          <:footer>
            <.drawer
              id="drawer-nested-3"
              nested
              parent="drawer-nested-2"
              swipe_direction="right"
              trigger_variant="outline"
            >
              <:trigger>Open Third Drawer</:trigger>
              <:title>Third Drawer</:title>
              <:description>Two drawers are stacked behind this one.</:description>
              <.drawer_placeholder />
              <:footer>
                <.drawer
                  id="drawer-nested-4"
                  nested
                  parent="drawer-nested-3"
                  swipe_direction="right"
                  trigger_variant="outline"
                >
                  <:trigger>Open Fourth Drawer</:trigger>
                  <:title>Fourth Drawer</:title>
                  <:description>This is the frontmost drawer in the stack.</:description>
                  <.drawer_placeholder />
                  <:close variant="outline">Close</:close>
                </.drawer>
              </:footer>
              <:close variant="outline">Close</:close>
            </.drawer>
          </:footer>
          <:close variant="outline">Close</:close>
        </.drawer>
      </:footer>
      <:close variant="outline">Close</:close>
    </.drawer>
    """
  end

  defp drawer_non_modal(assigns) do
    ~H"""
    <.drawer
      id="drawer-non-modal"
      modal={false}
      disable_pointer_dismissal
      swipe_direction="right"
      trigger_variant="outline"
    >
      <:trigger>Non Modal</:trigger>
      <:title>Non Modal Drawer</:title>
      <div class="flex-1 p-4">
        <div class="rounded-2xl bg-muted group-data-[swipe-axis=x]/drawer-popup:size-full group-data-[swipe-axis=y]/drawer-popup:h-80 group-data-[swipe-axis=y]/drawer-popup:w-full" />
      </div>
      <:close>Close</:close>
    </.drawer>
    """
  end

  defp drawer_snap_points(assigns) do
    ~H"""
    <.drawer
      id="drawer-snap-points"
      snap_points={["31rem", 1]}
      show_swipe_handle
      trigger_variant="outline"
    >
      <:trigger>Open Snap Drawer</:trigger>
      <:title>Snap points</:title>
      <:description>
        Drag the drawer to snap between a compact peek and a near full-height view.
      </:description>
      <div class="flex-1 p-4">
        <div class="rounded-2xl bg-muted group-data-[swipe-axis=x]/drawer-popup:size-full group-data-[swipe-axis=y]/drawer-popup:h-80 group-data-[swipe-axis=y]/drawer-popup:w-full" />
      </div>
      <:close>Close</:close>
    </.drawer>
    """
  end

  defp drawer_dialog(assigns) do
    ~H"""
    <div id="drawer-dialog-responsive" phx-hook="LiveBase.ResponsiveDialog" class="contents">
      <div data-lb-desktop>
        <.dialog id="drawer-dialog-desktop" trigger_variant="outline">
          <:trigger>Edit Profile</:trigger>
          <:title>Edit profile</:title>
          <:description>
            Make changes to your profile here. Click save when you're done.
          </:description>
          <.drawer_profile_form id_prefix="drawer-dialog-desktop" />
        </.dialog>
      </div>
      <div data-lb-mobile hidden>
        <.drawer id="drawer-dialog-mobile" trigger_variant="outline" header_class="text-left">
          <:trigger>Edit Profile</:trigger>
          <:title>Edit profile</:title>
          <:description>
            Make changes to your profile here. Click save when you're done.
          </:description>
          <.drawer_profile_form id_prefix="drawer-dialog-mobile" class="p-4" />
        </.drawer>
      </div>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:id_prefix, :string, required: true)

  defp drawer_profile_form(assigns) do
    ~H"""
    <form class={["grid items-start gap-6", @class]}>
      <div class="grid gap-3">
        <.label for={"#{@id_prefix}-email"}>Email</.label>
        <.input type="email" id={"#{@id_prefix}-email"} value="shadcn@example.com" />
      </div>
      <div class="grid gap-3">
        <.label for={"#{@id_prefix}-username"}>Username</.label>
        <.input id={"#{@id_prefix}-username"} value="@shadcn" />
      </div>
      <.button type="submit">Save changes</.button>
    </form>
    """
  end

  defp drawer_placeholder(assigns) do
    ~H"""
    <div class="flex-1 p-4">
      <div class="bg-muted group-data-[swipe-axis=x]/drawer-popup:size-full group-data-[swipe-axis=y]/drawer-popup:aspect-video group-data-[swipe-axis=y]/drawer-popup:w-full" />
    </div>
    """
  end

  defp menubar_default(assigns) do
    ~H"""
    <.menubar id="menubar-default" class="w-72">
      <.menubar_menu id="menubar-default-file" tabindex={0}>
        <:trigger>File</:trigger>
        <:entry kind="item" value="new-tab" section="new" shortcut="⌘T">New Tab</:entry>
        <:entry kind="item" value="new-window" section="new" shortcut="⌘N">New Window</:entry>
        <:entry kind="item" value="incognito" section="new" disabled>New Incognito Window</:entry>
        <:entry kind="separator" />
        <:entry
          kind="submenu"
          value="share"
          section="share"
          items={[
            %{kind: "item", value: "email-link", label: "Email link", section: "share"},
            %{kind: "item", value: "messages", label: "Messages", section: "share"},
            %{kind: "item", value: "notes", label: "Notes", section: "share"}
          ]}
        >
          Share
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="print" section="print" shortcut="⌘P">Print...</:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-default-edit" tabindex={-1}>
        <:trigger>Edit</:trigger>
        <:entry kind="item" value="undo" section="history" shortcut="⌘Z">Undo</:entry>
        <:entry kind="item" value="redo" section="history" shortcut="⇧⌘Z">Redo</:entry>
        <:entry kind="separator" />
        <:entry
          kind="submenu"
          value="find"
          section="find"
          items={[
            %{kind: "item", value: "search-web", label: "Search the web", section: "search"},
            %{kind: "separator"},
            %{kind: "item", value: "find", label: "Find...", section: "find"},
            %{kind: "item", value: "find-next", label: "Find Next", section: "find"},
            %{kind: "item", value: "find-previous", label: "Find Previous", section: "find"}
          ]}
        >
          Find
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="cut" section="clipboard">Cut</:entry>
        <:entry kind="item" value="copy" section="clipboard">Copy</:entry>
        <:entry kind="item" value="paste" section="clipboard">Paste</:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-default-view" class="w-44" tabindex={-1}>
        <:trigger>View</:trigger>
        <:entry kind="checkbox" value="bookmarks" section="display">Bookmarks Bar</:entry>
        <:entry kind="checkbox" value="full-urls" section="display" checked>Full URLs</:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="reload" section="reload" inset shortcut="⌘R">Reload</:entry>
        <:entry kind="item" value="force-reload" section="reload" disabled inset shortcut="⇧⌘R">
          Force Reload
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="fullscreen" section="fullscreen" inset>Toggle Fullscreen</:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="hide-sidebar" section="sidebar" inset>Hide Sidebar</:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-default-profiles" tabindex={-1}>
        <:trigger>Profiles</:trigger>
        <:entry
          kind="radio-group"
          group="profile"
          value="benoit"
          items={[
            %{value: "andy", label: "Andy"},
            %{value: "benoit", label: "Benoit"},
            %{value: "Luis", label: "Luis"}
          ]}
        />
        <:entry kind="separator" />
        <:entry kind="item" value="edit-profile" section="edit" inset>Edit...</:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="add-profile" section="add" inset>Add Profile...</:entry>
      </.menubar_menu>
    </.menubar>
    """
  end

  defp menubar_checkbox(assigns) do
    ~H"""
    <.menubar id="menubar-checkbox" class="w-72">
      <.menubar_menu id="menubar-checkbox-view" class="w-64" tabindex={0}>
        <:trigger>View</:trigger>
        <:entry kind="checkbox" value="bookmarks">Always Show Bookmarks Bar</:entry>
        <:entry kind="checkbox" value="full-urls" checked>Always Show Full URLs</:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="reload" inset shortcut="⌘R">Reload</:entry>
        <:entry kind="item" value="force-reload" disabled inset shortcut="⇧⌘R">
          Force Reload
        </:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-checkbox-format" tabindex={-1}>
        <:trigger>Format</:trigger>
        <:entry kind="checkbox" value="strikethrough" checked>Strikethrough</:entry>
        <:entry kind="checkbox" value="code">Code</:entry>
        <:entry kind="checkbox" value="superscript">Superscript</:entry>
      </.menubar_menu>
    </.menubar>
    """
  end

  defp menubar_radio(assigns) do
    ~H"""
    <.menubar id="menubar-radio" class="w-72">
      <.menubar_menu id="menubar-radio-profiles" tabindex={0}>
        <:trigger>Profiles</:trigger>
        <:entry
          kind="radio-group"
          group="profile"
          value="benoit"
          items={[
            %{value: "andy", label: "Andy"},
            %{value: "benoit", label: "Benoit"},
            %{value: "luis", label: "Luis"}
          ]}
        />
        <:entry kind="separator" />
        <:entry kind="item" value="edit" inset>Edit...</:entry>
        <:entry kind="item" value="add-profile" inset>Add Profile...</:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-radio-theme" tabindex={-1}>
        <:trigger>Theme</:trigger>
        <:entry
          kind="radio-group"
          group="theme"
          value="system"
          items={[
            %{value: "light", label: "Light"},
            %{value: "dark", label: "Dark"},
            %{value: "system", label: "System"}
          ]}
        />
      </.menubar_menu>
    </.menubar>
    """
  end

  defp menubar_submenu(assigns) do
    ~H"""
    <.menubar id="menubar-submenu" class="w-72">
      <.menubar_menu id="menubar-submenu-file" tabindex={0}>
        <:trigger>File</:trigger>
        <:entry
          kind="submenu"
          value="share"
          items={[
            %{kind: "item", value: "email-link", label: "Email link"},
            %{kind: "item", value: "messages", label: "Messages"},
            %{kind: "item", value: "notes", label: "Notes"}
          ]}
        >
          Share
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="print" shortcut="⌘P">Print...</:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-submenu-edit" tabindex={-1}>
        <:trigger>Edit</:trigger>
        <:entry kind="item" value="undo" shortcut="⌘Z">Undo</:entry>
        <:entry kind="item" value="redo" shortcut="⇧⌘Z">Redo</:entry>
        <:entry kind="separator" />
        <:entry
          kind="submenu"
          value="find"
          items={[
            %{kind: "item", value: "find", label: "Find..."},
            %{kind: "item", value: "find-next", label: "Find Next"},
            %{kind: "item", value: "find-previous", label: "Find Previous"}
          ]}
        >
          Find
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="cut">Cut</:entry>
        <:entry kind="item" value="copy">Copy</:entry>
        <:entry kind="item" value="paste">Paste</:entry>
      </.menubar_menu>
    </.menubar>
    """
  end

  defp menubar_icons(assigns) do
    ~H"""
    <.menubar id="menubar-icons" class="w-72">
      <.menubar_menu id="menubar-icons-file" tabindex={0}>
        <:trigger>File</:trigger>
        <:entry kind="item" value="new-file" shortcut="⌘N">
          <LiveShadcn.Icon.icon name="file" /> New File
        </:entry>
        <:entry kind="item" value="open-folder">
          <LiveShadcn.Icon.icon name="folder" /> Open Folder
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="save" shortcut="⌘S">
          <LiveShadcn.Icon.icon name="save" /> Save
        </:entry>
      </.menubar_menu>
      <.menubar_menu id="menubar-icons-more" tabindex={-1}>
        <:trigger>More</:trigger>
        <:entry kind="item" value="settings" section="more">
          <LiveShadcn.Icon.icon name="settings" /> Settings
        </:entry>
        <:entry kind="item" value="help" section="more">
          <LiveShadcn.Icon.icon name="circle-help" /> Help
        </:entry>
        <:entry kind="separator" section="more" />
        <:entry kind="item" value="delete" variant="destructive" section="more">
          <LiveShadcn.Icon.icon name="trash" /> Delete
        </:entry>
      </.menubar_menu>
    </.menubar>
    """
  end

  defp menubar_rtl(assigns) do
    ~H"""
    <.menubar id="menubar-rtl" class="w-72" dir="rtl">
      <.menubar_menu
        id="menubar-rtl-file"
        align="end"
        tabindex={0}
        content_attrs={%{dir: "rtl"}}
      >
        <:trigger>ملف</:trigger>
        <:entry kind="item" value="new-tab" section="new" shortcut="⌘T">علامة تبويب جديدة</:entry>
        <:entry kind="item" value="new-window" section="new" shortcut="⌘N">نافذة جديدة</:entry>
        <:entry kind="item" value="incognito" section="new" disabled>
          نافذة التصفح المتخفي الجديدة
        </:entry>
        <:entry kind="separator" />
        <:entry
          kind="submenu"
          value="share"
          section="share"
          content_attrs={%{:"data-lang" => "ar", dir: "rtl"}}
          items={[
            %{kind: "item", value: "email-link", label: "رابط البريد الإلكتروني", section: "share"},
            %{kind: "item", value: "messages", label: "الرسائل", section: "share"},
            %{kind: "item", value: "notes", label: "الملاحظات", section: "share"}
          ]}
        >
          مشاركة
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="print" section="print" shortcut="⌘P">طباعة...</:entry>
      </.menubar_menu>
      <.menubar_menu
        id="menubar-rtl-edit"
        align="end"
        tabindex={-1}
        content_attrs={%{:"data-lang" => "ar", dir: "rtl"}}
      >
        <:trigger>تعديل</:trigger>
        <:entry kind="item" value="undo" section="history" shortcut="⌘Z">تراجع</:entry>
        <:entry kind="item" value="redo" section="history" shortcut="⇧⌘Z">إعادة</:entry>
        <:entry kind="separator" />
        <:entry
          kind="submenu"
          value="find"
          section="find"
          content_attrs={%{:"data-lang" => "ar", dir: "rtl"}}
          items={[
            %{kind: "item", value: "search-web", label: "البحث على الويب", section: "search"},
            %{kind: "separator"},
            %{kind: "item", value: "find", label: "بحث...", section: "find"},
            %{kind: "item", value: "find-next", label: "البحث التالي", section: "find"},
            %{kind: "item", value: "find-previous", label: "البحث السابق", section: "find"}
          ]}
        >
          بحث
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="cut" section="clipboard">قص</:entry>
        <:entry kind="item" value="copy" section="clipboard">نسخ</:entry>
        <:entry kind="item" value="paste" section="clipboard">لصق</:entry>
      </.menubar_menu>
      <.menubar_menu
        id="menubar-rtl-view"
        class="w-44"
        align="end"
        tabindex={-1}
        content_attrs={%{:"data-lang" => "ar", dir: "rtl"}}
      >
        <:trigger>عرض</:trigger>
        <:entry kind="checkbox" value="bookmarks" section="display">شريط الإشارات المرجعية</:entry>
        <:entry kind="checkbox" value="full-urls" section="display" checked>
          عناوين URL الكاملة
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="reload" section="reload" inset shortcut="⌘R">إعادة تحميل</:entry>
        <:entry kind="item" value="force-reload" section="reload" disabled inset shortcut="⇧⌘R">
          إعادة تحميل قسري
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="fullscreen" section="fullscreen" inset>
          تبديل وضع ملء الشاشة
        </:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="hide-sidebar" section="sidebar" inset>إخفاء الشريط الجانبي</:entry>
      </.menubar_menu>
      <.menubar_menu
        id="menubar-rtl-profiles"
        align="end"
        tabindex={-1}
        content_attrs={%{:"data-lang" => "ar", dir: "rtl"}}
      >
        <:trigger>الملفات الشخصية</:trigger>
        <:entry
          kind="radio-group"
          group="profile"
          value="benoit"
          items={[
            %{value: "andy", label: "Andy"},
            %{value: "benoit", label: "Benoit"},
            %{value: "Luis", label: "Luis"}
          ]}
        />
        <:entry kind="separator" />
        <:entry kind="item" value="edit-profile" section="edit" inset>تعديل...</:entry>
        <:entry kind="separator" />
        <:entry kind="item" value="add-profile" section="add" inset>إضافة ملف شخصي...</:entry>
      </.menubar_menu>
    </.menubar>
    """
  end

  defp input_group_default(assigns) do
    ~H"""
    <.input_group class="max-w-xs">
      <.input_group_input placeholder="Search..." />
      <.input_group_addon><LiveShadcn.Icon.icon name="search" /></.input_group_addon>
      <.input_group_addon align="inline-end">12 results</.input_group_addon>
    </.input_group>
    """
  end

  defp input_group_inline_start(assigns) do
    ~H"""
    <.field class="max-w-sm">
      <.field_label for="inline-start-input">Input</.field_label>
      <.input_group>
        <.input_group_input id="inline-start-input" placeholder="Search..." />
        <.input_group_addon align="inline-start">
          <LiveShadcn.Icon.icon name="search" class="text-muted-foreground" />
        </.input_group_addon>
      </.input_group>
      <.field_description>Icon positioned at the start.</.field_description>
    </.field>
    """
  end

  defp input_group_inline_end(assigns) do
    ~H"""
    <.field class="max-w-sm">
      <.field_label for="inline-end-input">Input</.field_label>
      <.input_group>
        <.input_group_input id="inline-end-input" type="password" placeholder="Enter password" />
        <.input_group_addon align="inline-end">
          <LiveShadcn.Icon.icon name="eye-off" />
        </.input_group_addon>
      </.input_group>
      <.field_description>Icon positioned at the end.</.field_description>
    </.field>
    """
  end

  defp input_group_block_start(assigns) do
    ~H"""
    <.field_group class="max-w-sm">
      <.field>
        <.field_label for="block-start-input">Input</.field_label>
        <.input_group class="h-auto">
          <.input_group_input id="block-start-input" placeholder="Enter your name" />
          <.input_group_addon align="block-start">
            <.input_group_text>Full Name</.input_group_text>
          </.input_group_addon>
        </.input_group>
        <.field_description>Header positioned above the input.</.field_description>
      </.field>
      <.field>
        <.field_label for="block-start-textarea">Textarea</.field_label>
        <.input_group>
          <.input_group_textarea
            id="block-start-textarea"
            placeholder="console.log('Hello, world!');"
            class="font-mono text-sm"
          />
          <.input_group_addon align="block-start">
            <LiveShadcn.Icon.icon name="file-code" class="text-muted-foreground" />
            <.input_group_text class="font-mono">script.js</.input_group_text>
            <.input_group_button size="icon-xs" class="ml-auto"><LiveShadcn.Icon.icon name="copy" /><span class="sr-only">Copy</span></.input_group_button>
          </.input_group_addon>
        </.input_group>
        <.field_description>Header positioned above the textarea.</.field_description>
      </.field>
    </.field_group>
    """
  end

  defp input_group_block_end(assigns) do
    ~H"""
    <.field_group class="max-w-sm">
      <.field>
        <.field_label for="block-end-input">Input</.field_label>
        <.input_group class="h-auto">
          <.input_group_input id="block-end-input" placeholder="Enter amount" />
          <.input_group_addon align="block-end">
            <.input_group_text>USD</.input_group_text>
          </.input_group_addon>
        </.input_group>
        <.field_description>Footer positioned below the input.</.field_description>
      </.field>
      <.field>
        <.field_label for="block-end-textarea">Textarea</.field_label>
        <.input_group>
          <.input_group_textarea id="block-end-textarea" placeholder="Write a comment..." />
          <.input_group_addon align="block-end">
            <.input_group_text>0/280</.input_group_text><.input_group_button
              variant="default"
              size="sm"
              class="ml-auto"
            >Post</.input_group_button>
          </.input_group_addon>
        </.input_group>
        <.field_description>Footer positioned below the textarea.</.field_description>
      </.field>
    </.field_group>
    """
  end

  defp input_group_icon(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-6">
      <.input_group>
        <.input_group_input placeholder="Search..." /><.input_group_addon>
          <LiveShadcn.Icon.icon name="search" />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input type="email" placeholder="Enter your email" /><.input_group_addon>
          <LiveShadcn.Icon.icon name="mail" />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Card number" /><.input_group_addon>
          <LiveShadcn.Icon.icon name="credit-card" />
        </.input_group_addon><.input_group_addon align="inline-end">
          <LiveShadcn.Icon.icon name="check" />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Card number" /><.input_group_addon align="inline-end">
          <LiveShadcn.Icon.icon name="star" /><LiveShadcn.Icon.icon name="info" />
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_text_example(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-6">
      <.input_group>
        <.input_group_addon>
          <.input_group_text>$</.input_group_text>
        </.input_group_addon><.input_group_input placeholder="0.00" /><.input_group_addon align="inline-end">
          <.input_group_text>USD</.input_group_text>
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_addon>
          <.input_group_text>https://</.input_group_text>
        </.input_group_addon><.input_group_input placeholder="example.com" class="pl-0.5!" /><.input_group_addon align="inline-end">
          <.input_group_text>.com</.input_group_text>
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Enter your username" /><.input_group_addon align="inline-end">
          <.input_group_text>@company.com</.input_group_text>
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_textarea placeholder="Enter your message" /><.input_group_addon align="block-end">
          <.input_group_text class="text-xs text-muted-foreground">
            120 characters left
          </.input_group_text>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_button_example(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-6">
      <.input_group>
        <.input_group_input placeholder="https://x.com/shadcn" readonly />
        <.input_group_addon align="inline-end">
          <.input_group_button
            id="input-group-copy"
            aria-label="Copy"
            title="Copy"
            size="icon-xs"
            phx-hook={LiveBase.Clipboard.hook()}
            phx-mounted={LiveBase.Clipboard.owned_attributes()}
            data-lb-clipboard="https://x.com/shadcn"
          >
            <.tabler_icon data-lb-state="copied" hidden name="check" />
            <.tabler_icon data-lb-state="idle" name="copy" />
          </.input_group_button>
        </.input_group_addon>
      </.input_group>
      <.input_group class="[--radius:9999px]">
        <%!-- The upstream icon triggers have no visible name. These labels satisfy the local accessibility gate. --%>
        <.popover
          id="input-group-security"
          trigger_target="wrapper"
          trigger_wrapper_slot="popover-trigger"
          trigger_wrapper_align="inline-start"
          trigger_wrapper_class="cn-input-group-addon flex cursor-text items-center justify-center select-none cn-input-group-addon-align-inline-start order-first"
          trigger_slot="button"
          trigger_label="Connection security information"
          trigger_variant="secondary"
          trigger_data_size="icon-xs"
          trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs"
          align="start"
          class="flex flex-col gap-1 rounded-xl text-sm"
        >
          <:trigger><.tabler_icon name="info-circle" /></:trigger>
          <p class="font-medium">Your connection is not secure.</p>
          <p>You should not enter any sensitive information on this site.</p>
        </.popover>
        <.input_group_addon class="pl-1.5 text-muted-foreground">https://</.input_group_addon>
        <.input_group_input id="input-secure-19" />
        <.input_group_addon align="inline-end">
          <.input_group_button
            id="input-group-favorite"
            size="icon-xs"
            aria-label="Favorite"
            phx-click={
              Phoenix.LiveView.JS.toggle_attribute({"data-favorite", "true", "false"},
                to: "#input-group-favorite-icon"
              )
            }
          >
            <.tabler_icon
              id="input-group-favorite-icon"
              name="star"
              data-favorite="false"
              class="data-[favorite=true]:fill-blue-600 data-[favorite=true]:stroke-blue-600"
            />
          </.input_group_button>
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Type to search..." /><.input_group_addon align="inline-end">
          <.input_group_button variant="secondary">Search</.input_group_button>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_kbd(assigns) do
    ~H"""
    <.input_group class="max-w-sm">
      <.input_group_input placeholder="Search..." />
      <.input_group_addon>
        <LiveShadcn.Icon.icon name="search" class="text-muted-foreground" />
      </.input_group_addon>
      <.input_group_addon align="inline-end">
        <.kbd>⌘K</.kbd>
      </.input_group_addon>
    </.input_group>
    """
  end

  defp input_group_dropdown(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-4">
      <.input_group>
        <.input_group_input placeholder="Enter file name" />
        <.input_group_addon align="inline-end" class="-mr-1">
          <.dropdown_menu
            id="input-group-more"
            trigger_slot="dropdown-menu-trigger"
            trigger_variant="ghost"
            trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs"
            trigger_attrs={%{"aria-label" => "More", "data-size" => "icon-xs"}}
            align="end"
            side_offset="8"
            align_offset="-4"
            grouped
          >
            <:trigger><LiveShadcn.Icon.icon name="ellipsis" /></:trigger>
            <:entry kind="item" value="settings">Settings</:entry>
            <:entry kind="item" value="copy-path">Copy path</:entry>
            <:entry kind="item" value="open-location">Open location</:entry>
          </.dropdown_menu>
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Enter search query" />
        <.input_group_addon align="inline-end" class="-mr-1">
          <.dropdown_menu
            id="input-group-search-in"
            trigger_slot="dropdown-menu-trigger"
            trigger_variant="ghost"
            trigger_class="cn-input-group-button flex items-center shadow-none cn-input-group-button-size-xs pr-1.5! text-xs"
            trigger_attrs={%{"data-size" => "xs"}}
            align="end"
            side_offset="8"
            align_offset="-4"
            grouped
          >
            <:trigger>
              Search In... <LiveShadcn.Icon.icon name="chevron-down" class="size-3" />
            </:trigger>
            <:entry kind="item" value="documentation">Documentation</:entry>
            <:entry kind="item" value="blog-posts">Blog Posts</:entry>
            <:entry kind="item" value="changelog">Changelog</:entry>
          </.dropdown_menu>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_spinner(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-4">
      <.input_group>
        <.input_group_input placeholder="Searching..." /><.input_group_addon align="inline-end">
          <.spinner />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Processing..." /><.input_group_addon>
          <.spinner />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Saving changes..." /><.input_group_addon align="inline-end">
          <.input_group_text>Saving...</.input_group_text><.spinner />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="Refreshing data..." /><.input_group_addon>
          <LiveShadcn.Icon.icon name="loader" class="animate-spin" />
        </.input_group_addon><.input_group_addon align="inline-end">
          <.input_group_text class="text-muted-foreground">Please wait...</.input_group_text>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_textarea_example(assigns) do
    ~H"""
    <div class="grid w-full max-w-md gap-4">
      <.input_group>
        <.input_group_textarea
          id="textarea-code-32"
          placeholder="console.log('Hello, world!');"
          class="min-h-[200px]"
        />
        <.input_group_addon align="block-end" class="border-t">
          <.input_group_text>Line 1, Column 1</.input_group_text><.input_group_button
            size="sm"
            class="ml-auto"
            variant="default"
          >Run <.tabler_icon name="corner-down-left" /></.input_group_button>
        </.input_group_addon>
        <.input_group_addon align="block-start" class="border-b">
          <%!-- The upstream icon-only actions have no visible name. These labels satisfy the local accessibility gate. --%>
          <.input_group_text class="font-mono font-medium">
            <.tabler_icon name="brand-javascript" /> script.js
          </.input_group_text>
          <.input_group_button class="ml-auto" size="icon-xs" aria-label="Refresh"><.tabler_icon name="refresh" /></.input_group_button>
          <.input_group_button variant="ghost" size="icon-xs" aria-label="Copy"><.tabler_icon name="copy" /></.input_group_button>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_custom(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-6">
      <.input_group>
        <textarea
          data-slot="input-group-control"
          data-lb-autosize
          placeholder="Autoresize textarea..."
          class="flex field-sizing-content min-h-16 w-full resize-none rounded-md bg-transparent px-3 py-2.5 text-base transition-[color,box-shadow] outline-none md:text-sm"
        ></textarea>
        <.input_group_addon align="block-end">
          <.input_group_button class="ml-auto" size="sm" variant="default">Submit</.input_group_button>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp input_group_rtl(assigns) do
    ~H"""
    <div class="grid w-full max-w-sm gap-6">
      <.input_group class="max-w-xs">
        <.input_group_input placeholder="بحث..." /><.input_group_addon>
          <LiveShadcn.Icon.icon name="search" />
        </.input_group_addon><.input_group_addon align="inline-end">١٢ نتيجة</.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="جاري البحث..." /><.input_group_addon align="inline-end">
          <.spinner />
        </.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_input placeholder="جاري حفظ التغييرات..." /><.input_group_addon align="inline-end">
          <.input_group_text>جاري الحفظ...</.input_group_text><.spinner />
        </.input_group_addon>
      </.input_group>
      <.field_group class="max-w-sm">
        <.field>
          <.field_label for="rtl-textarea">منطقة النص</.field_label>
          <.input_group>
            <.input_group_textarea id="rtl-textarea" placeholder="اكتب تعليقًا..." /><.input_group_addon align="block-end">
              <.input_group_text>٠/٢٨٠</.input_group_text><.input_group_button
                variant="default"
                size="sm"
                class="ms-auto"
              >نشر</.input_group_button>
            </.input_group_addon>
          </.input_group>
          <.field_description>تذييل موضع أسفل منطقة النص.</.field_description>
        </.field>
      </.field_group>
    </div>
    """
  end

  defp native_select_default(assigns) do
    ~H"""
    <.native_select>
      <.native_select_option value="">Select status</.native_select_option>
      <.native_select_option value="todo">Todo</.native_select_option>
      <.native_select_option value="in-progress">In Progress</.native_select_option>
      <.native_select_option value="done">Done</.native_select_option>
      <.native_select_option value="cancelled">Cancelled</.native_select_option>
    </.native_select>
    """
  end

  defp native_select_groups(assigns) do
    ~H"""
    <.native_select>
      <.native_select_option value="">Select department</.native_select_option>
      <.native_select_opt_group label="Engineering">
        <.native_select_option value="frontend">Frontend</.native_select_option>
        <.native_select_option value="backend">Backend</.native_select_option>
        <.native_select_option value="devops">DevOps</.native_select_option>
      </.native_select_opt_group>
      <.native_select_opt_group label="Sales">
        <.native_select_option value="sales-rep">Sales Rep</.native_select_option>
        <.native_select_option value="account-manager">Account Manager</.native_select_option>
        <.native_select_option value="sales-director">Sales Director</.native_select_option>
      </.native_select_opt_group>
      <.native_select_opt_group label="Operations">
        <.native_select_option value="support">Customer Support</.native_select_option>
        <.native_select_option value="product-manager">Product Manager</.native_select_option>
        <.native_select_option value="ops-manager">Operations Manager</.native_select_option>
      </.native_select_opt_group>
    </.native_select>
    """
  end

  defp native_select_disabled(assigns) do
    ~H"""
    <.native_select disabled>
      <.native_select_option value="">Disabled</.native_select_option>
      <.native_select_option value="apple">Apple</.native_select_option>
      <.native_select_option value="banana">Banana</.native_select_option>
      <.native_select_option value="blueberry">Blueberry</.native_select_option>
    </.native_select>
    """
  end

  defp native_select_invalid(assigns) do
    ~H"""
    <.native_select aria-invalid="true">
      <.native_select_option value="">Error state</.native_select_option>
      <.native_select_option value="apple">Apple</.native_select_option>
      <.native_select_option value="banana">Banana</.native_select_option>
      <.native_select_option value="blueberry">Blueberry</.native_select_option>
    </.native_select>
    """
  end

  defp native_select_rtl(assigns) do
    ~H"""
    <.native_select dir="rtl">
      <.native_select_option value="">اختر الحالة</.native_select_option>
      <.native_select_option value="todo">مهام</.native_select_option>
      <.native_select_option value="in-progress">قيد التنفيذ</.native_select_option>
      <.native_select_option value="done">منجز</.native_select_option>
      <.native_select_option value="cancelled">ملغي</.native_select_option>
    </.native_select>
    """
  end

  # `sidebar_inset` is left out on purpose. It is a `<main>` — the page's own
  # content area, beside the sidebar — and this page already has one around
  # every example. Drawing a second inside the first is what a real page never
  # does, and axe is right to say so.
  defp scroll_area_default(assigns) do
    ~H"""
    <.scroll_area id="tags" class="h-72 w-48 rounded-md border">
      <div class="p-4">
        <h4 class="mb-4 text-sm leading-none font-medium">Tags</h4>
        <%= for number <- 50..1//-1 do %>
          <div class="text-sm">v1.2.0-beta.{number}</div>
          <.separator class="my-2" />
        <% end %>
      </div>
    </.scroll_area>
    """
  end

  defp scroll_area_horizontal(assigns) do
    works = [
      {"Ornella Binni",
       "https://images.unsplash.com/photo-1465869185982-5a1a7522cbcb?auto=format&fit=crop&w=300&q=80"},
      {"Tom Byrom",
       "https://images.unsplash.com/photo-1548516173-3cabfa4607e9?auto=format&fit=crop&w=300&q=80"},
      {"Vladimir Malyavko",
       "https://images.unsplash.com/photo-1494337480532-3725c85fd2ab?auto=format&fit=crop&w=300&q=80"}
    ]

    assigns = assign(assigns, :works, works)

    ~H"""
    <.scroll_area id="artwork" horizontal class="w-96 rounded-md border whitespace-nowrap">
      <div class="flex w-max space-x-4 p-4">
        <figure :for={{artist, art} <- @works} class="shrink-0">
          <div class="overflow-hidden rounded-md">
            <img
              src={art}
              alt={"Photo by #{artist}"}
              class="aspect-[3/4] h-fit w-fit object-cover"
              width="300"
              height="400"
            />
          </div>
          <figcaption class="pt-2 text-xs text-muted-foreground">
            Photo by <span class="font-semibold text-foreground">{artist}</span>
          </figcaption>
        </figure>
      </div>
    </.scroll_area>
    """
  end

  defp scroll_area_rtl(assigns) do
    ~H"""
    <.scroll_area id="tags-rtl" class="h-72 w-48 rounded-md border" dir="rtl">
      <div class="p-4">
        <h4 class="mb-4 text-sm leading-none font-medium">العلامات</h4>
        <%= for number <- 50..1//-1 do %>
          <div class="text-sm">v1.2.0-beta.{number}</div>
          <.separator class="my-2" />
        <% end %>
      </div>
    </.scroll_area>
    """
  end

  defp slider_default(assigns) do
    ~H"""
    <.slider
      id="slider-demo"
      value={[75]}
      max={100}
      step={1}
      label="Value"
      class="mx-auto w-full max-w-xs"
    />
    """
  end

  defp slider_range(assigns) do
    ~H"""
    <.slider
      id="slider-range"
      value={[25, 50]}
      max={100}
      step={5}
      label="Range value"
      class="mx-auto w-full max-w-xs"
    />
    """
  end

  defp slider_multiple(assigns) do
    ~H"""
    <.slider
      id="slider-multiple"
      value={[10, 20, 70]}
      max={100}
      step={10}
      label="Value"
      class="mx-auto w-full max-w-xs"
    />
    """
  end

  defp slider_vertical(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-xs items-center justify-center gap-6">
      <.slider
        id="slider-vertical-first"
        value={[50]}
        max={100}
        step={1}
        orientation="vertical"
        label="First value"
        class="h-40"
      />
      <.slider
        id="slider-vertical-second"
        value={[25]}
        max={100}
        step={1}
        orientation="vertical"
        label="Second value"
        class="h-40"
      />
    </div>
    """
  end

  defp slider_controlled(assigns) do
    ~H"""
    <div class="mx-auto grid w-full max-w-xs gap-3">
      <div class="flex items-center justify-between gap-2">
        <.label for="slider-demo-temperature-0">Temperature</.label>
        <span class="text-sm text-muted-foreground">
          {Enum.join(@slider_controlled_values, ", ")}
        </span>
      </div>
      <.slider
        id="slider-demo-temperature"
        value={@slider_controlled_values}
        min={0}
        max={1}
        step={0.1}
        label="Temperature"
        on_change="slider_controlled_value"
      />
    </div>
    """
  end

  defp slider_disabled(assigns) do
    ~H"""
    <.slider
      id="slider-disabled"
      value={[50]}
      max={100}
      step={1}
      disabled
      label="Value"
      class="mx-auto w-full max-w-xs"
    />
    """
  end

  defp slider_rtl(assigns) do
    ~H"""
    <.slider
      id="slider-rtl"
      value={[75]}
      max={100}
      step={1}
      label="Value"
      class="mx-auto w-full max-w-xs"
      dir="rtl"
    />
    """
  end

  defp toast_default(assigns) do
    ~H"""
    <.button variant="outline" phx-click="toast_add" phx-value-example="default">
      Show Toast
    </.button>
    <.toaster id="toast-default" dismiss="dismiss_toast" duration={0}>
      <:toast
        :for={notice <- @toast_examples["default"]}
        id={notice.id}
        type={notice.type}
        priority={notice[:priority]}
        title={notice.title}
        action_label={notice[:action_label]}
      >
        {notice.description}
      </:toast>
    </.toaster>
    """
  end

  defp toast_types(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.button variant="outline" phx-click="toast_add" phx-value-example="types">
        Default
      </.button>
      <.button
        variant="outline"
        phx-click="toast_add"
        phx-value-example="types"
        phx-value-type="success"
      >
        Success
      </.button>
      <.button
        variant="outline"
        phx-click="toast_add"
        phx-value-example="types"
        phx-value-type="info"
      >
        Info
      </.button>
      <.button
        variant="outline"
        phx-click="toast_add"
        phx-value-example="types"
        phx-value-type="warning"
      >
        Warning
      </.button>
      <.button
        variant="outline"
        phx-click="toast_add"
        phx-value-example="types"
        phx-value-type="error"
      >
        Error
      </.button>
    </div>
    <.toaster id="toast-types" dismiss="dismiss_toast" duration={0}>
      <:toast
        :for={notice <- @toast_examples["types"]}
        id={notice.id}
        type={notice.type}
        priority={notice[:priority]}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </.toaster>
    """
  end

  defp toast_promise(assigns) do
    ~H"""
    <.button variant="outline" phx-click="toast_promise">
      Create Event
    </.button>
    <.toaster id="toast-promise" dismiss="dismiss_toast" duration={0}>
      <:toast
        :for={notice <- @toast_examples["promise"]}
        id={notice.id}
        type={notice.type}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </.toaster>
    """
  end

  @sidebar_teams [
    %{name: "Acme Inc", plan: "Enterprise", icon: "gallery-vertical-end"},
    %{name: "Acme Corp.", plan: "Startup", icon: "audio-waveform"},
    %{name: "Evil Corp.", plan: "Free", icon: "command"}
  ]

  defp sidebar_teams, do: @sidebar_teams

  @sidebar_nav_main [
    %{
      title: "Playground",
      icon: "square-terminal",
      active: true,
      items: ["History", "Starred", "Settings"]
    },
    %{title: "Models", icon: "bot", active: false, items: ["Genesis", "Explorer", "Quantum"]},
    %{
      title: "Documentation",
      icon: "book-open",
      active: false,
      items: ["Introduction", "Get Started", "Tutorials", "Changelog"]
    },
    %{
      title: "Settings",
      icon: "settings-2",
      active: false,
      items: ["General", "Team", "Billing", "Limits"]
    }
  ]

  @sidebar_projects [
    %{name: "Design Engineering", icon: "frame"},
    %{name: "Sales & Marketing", icon: "chart-pie"},
    %{name: "Travel", icon: "map"}
  ]

  defp sidebar_default(assigns) do
    assigns =
      assign(assigns,
        teams: @sidebar_teams,
        active_team: sidebar_team(assigns.sidebar_active_team),
        nav_main: @sidebar_nav_main,
        projects: @sidebar_projects
      )

    ~H"""
    <.sidebar_provider>
      <.sidebar id="nav" collapsible="icon" phx-hook="SidebarPopupPlacement">
        <.sidebar_header>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.dropdown_menu
                id="sidebar-team"
                side="right"
                align="start"
                side_offset="4"
                grouped
                class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
                content_attrs={%{"data-lb-mobile-side" => "bottom"}}
                trigger_class={[
                  LiveShadcn.UI.Sidebar.sidebar_menu_button_class("lg"),
                  "data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                ]}
                trigger_attrs={sidebar_menu_button_attrs("lg")}
              >
                <:trigger>
                  <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
                    <LiveShadcn.Icon.icon name={@active_team.icon} class="size-4" />
                  </div>
                  <div class="grid flex-1 text-left text-sm leading-tight">
                    <span class="truncate font-medium">{@active_team.name}</span>
                    <span class="truncate text-xs">{@active_team.plan}</span>
                  </div>
                  <LiveShadcn.Icon.icon name="chevrons-up-down" class="ml-auto" />
                </:trigger>
                <:entry kind="label" class="text-xs text-muted-foreground">Teams</:entry>
                <:entry
                  :for={{team, index} <- Enum.with_index(@teams, 1)}
                  kind="item"
                  value={sidebar_team_id(team)}
                  class="gap-2 p-2"
                  shortcut={"⌘#{index}"}
                  phx-click={
                    Phoenix.LiveView.JS.push("sidebar_team_select",
                      value: %{team: sidebar_team_id(team)}
                    )
                  }
                >
                  <div class="flex size-6 items-center justify-center rounded-md border">
                    <LiveShadcn.Icon.icon name={team.icon} class="size-3.5 shrink-0" />
                  </div>
                  {team.name}
                </:entry>
                <:entry kind="separator" />
                <:entry kind="item" value="add-team" class="gap-2 p-2">
                  <div class="flex size-6 items-center justify-center rounded-md border bg-transparent">
                    <LiveShadcn.Icon.icon name="plus" class="size-4" />
                  </div>
                  <div class="font-medium text-muted-foreground">Add team</div>
                </:entry>
              </.dropdown_menu>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_header>

        <.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Platform</.sidebar_group_label>
            <.sidebar_menu>
              <.collapsible
                :for={item <- @nav_main}
                id={"sidebar-nav-#{String.downcase(item.title)}"}
                open={item.active}
                class="group/collapsible"
                trigger_class={LiveShadcn.UI.Sidebar.sidebar_menu_button_class()}
                trigger_attrs={sidebar_menu_button_attrs("default")}
                wrapper_tag="li"
                wrapper_attrs={sidebar_menu_item_attrs()}
              >
                <:trigger>
                  <LiveShadcn.Icon.icon name={item.icon} />
                  <span>{item.title}</span>
                  <LiveShadcn.Icon.icon
                    name="chevron-right"
                    class="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90"
                  />
                </:trigger>
                <.sidebar_menu_sub>
                  <.sidebar_menu_sub_item :for={subitem <- item.items}>
                    <.sidebar_menu_sub_button href="#">
                      <span>{subitem}</span>
                    </.sidebar_menu_sub_button>
                  </.sidebar_menu_sub_item>
                </.sidebar_menu_sub>
              </.collapsible>
            </.sidebar_menu>
          </.sidebar_group>

          <.sidebar_group class="group-data-[collapsible=icon]:hidden">
            <.sidebar_group_label>Projects</.sidebar_group_label>
            <.sidebar_menu>
              <.sidebar_menu_item :for={project <- @projects}>
                <.sidebar_menu_button comp="a" href="#">
                  <LiveShadcn.Icon.icon name={project.icon} />
                  <span>{project.name}</span>
                </.sidebar_menu_button>
                <.dropdown_menu
                  id={"sidebar-project-#{String.replace(String.downcase(project.name), ~r/[^a-z]+/, "-")}"}
                  side="right"
                  align="start"
                  class="w-48 rounded-lg"
                  trigger_class={LiveShadcn.UI.Sidebar.sidebar_menu_action_class(true)}
                  trigger_attrs={sidebar_menu_action_attrs()}
                >
                  <:trigger>
                    <LiveShadcn.Icon.icon name="ellipsis" /><span class="sr-only">More</span>
                  </:trigger>
                  <:entry kind="item" value="view">
                    <LiveShadcn.Icon.icon name="folder" class="text-muted-foreground" />
                    <span>View Project</span>
                  </:entry>
                  <:entry kind="item" value="share">
                    <LiveShadcn.Icon.icon name="forward" class="text-muted-foreground" />
                    <span>Share Project</span>
                  </:entry>
                  <:entry kind="separator" />
                  <:entry kind="item" value="delete">
                    <LiveShadcn.Icon.icon name="trash-2" class="text-muted-foreground" />
                    <span>Delete Project</span>
                  </:entry>
                </.dropdown_menu>
              </.sidebar_menu_item>
              <.sidebar_menu_item>
                <.sidebar_menu_button class="text-sidebar-foreground/70">
                  <LiveShadcn.Icon.icon name="ellipsis" class="text-sidebar-foreground/70" />
                  <span>More</span>
                </.sidebar_menu_button>
              </.sidebar_menu_item>
            </.sidebar_menu>
          </.sidebar_group>
        </.sidebar_content>

        <.sidebar_footer>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.dropdown_menu
                id="sidebar-user"
                side="right"
                align="end"
                side_offset="4"
                grouped
                class="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
                content_attrs={%{"data-lb-mobile-side" => "bottom"}}
                trigger_class={[
                  LiveShadcn.UI.Sidebar.sidebar_menu_button_class("lg"),
                  "data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
                ]}
                trigger_attrs={sidebar_menu_button_attrs("lg")}
              >
                <:trigger>
                  <.avatar class="h-8 w-8 rounded-lg">
                    <.avatar_image src="/avatars/shadcn.jpg" alt="shadcn" />
                    <.avatar_fallback class="rounded-lg">CN</.avatar_fallback>
                  </.avatar>
                  <div class="grid flex-1 text-left text-sm leading-tight">
                    <span class="truncate font-medium">shadcn</span>
                    <span class="truncate text-xs">m@example.com</span>
                  </div>
                  <LiveShadcn.Icon.icon name="chevrons-up-down" class="ml-auto size-4" />
                </:trigger>
                <:entry kind="label" class="p-0 font-normal">
                  <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                    <.avatar class="h-8 w-8 rounded-lg">
                      <.avatar_image src="/avatars/shadcn.jpg" alt="shadcn" />
                      <.avatar_fallback class="rounded-lg">CN</.avatar_fallback>
                    </.avatar>
                    <div class="grid flex-1 text-left text-sm leading-tight">
                      <span class="truncate font-medium">shadcn</span>
                      <span class="truncate text-xs">m@example.com</span>
                    </div>
                  </div>
                </:entry>
                <:entry kind="separator" />
                <:entry kind="item" value="upgrade">
                  <LiveShadcn.Icon.icon name="sparkles" /> Upgrade to Pro
                </:entry>
                <:entry kind="separator" />
                <:entry kind="item" value="account">
                  <LiveShadcn.Icon.icon name="badge-check" /> Account
                </:entry>
                <:entry kind="item" value="billing">
                  <LiveShadcn.Icon.icon name="credit-card" /> Billing
                </:entry>
                <:entry kind="item" value="notifications">
                  <LiveShadcn.Icon.icon name="bell" /> Notifications
                </:entry>
                <:entry kind="separator" />
                <:entry kind="item" value="log-out">
                  <LiveShadcn.Icon.icon name="log-out" /> Log out
                </:entry>
              </.dropdown_menu>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_footer>

        <.sidebar_rail for="nav" collapsible="icon" />
      </.sidebar>

      <.sidebar_inset>
        <header class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-12">
          <div class="flex items-center gap-2 px-4">
            <.sidebar_trigger for="nav" collapsible="icon" class="-ml-1" />
          </div>
        </header>
      </.sidebar_inset>
    </.sidebar_provider>
    """
  end

  defp sidebar_menu_button_attrs(size) do
    %{"data-active" => "false", "data-sidebar" => "menu-button", "data-size" => size}
  end

  defp sidebar_menu_action_attrs do
    %{"data-sidebar" => "menu-action"}
  end

  defp sidebar_menu_item_attrs do
    %{
      "class" => "group/menu-item relative",
      "data-sidebar" => "menu-item",
      "data-slot" => "sidebar-menu-item"
    }
  end

  defp question_default(assigns) do
    ~H"""
    <%= if response = @question_answers["default"] do %>
      <div class="w-full max-w-2xl rounded-lg border bg-background p-4 text-sm">
        <span class="text-muted-foreground">Answered: </span>
        {question_summary(response)}
      </div>
    <% else %>
      <.question
        id="question-default"
        class="w-full max-w-2xl"
        selection_mode="multiple"
        on_submit="question_submit"
      >
        <div class="space-y-1">
          <.question_prompt>What should the project include?</.question_prompt>
          <.question_description>
            Choose any features and add details if needed.
          </.question_description>
        </div>
        <.question_options selection_mode="multiple" aria-label="Project features">
          <.question_option value="authentication" role="checkbox" is_selected="false">
            Authentication
          </.question_option>
          <.question_option value="database" role="checkbox" is_selected="false">
            Database
          </.question_option>
          <.question_option value="payments" role="checkbox" is_selected="false">
            Payments
          </.question_option>
        </.question_options>
        <.question_input
          aria-label="Additional requirements"
          placeholder="Add any other requirements…"
        />
        <.question_actions>
          <.question_submit has_response="false">Answer</.question_submit>
        </.question_actions>
      </.question>
    <% end %>
    """
  end

  defp question_freeform(assigns) do
    ~H"""
    <%= if response = @question_answers["freeform"] do %>
      <div class="w-full max-w-2xl rounded-lg border bg-background p-4 text-sm">
        <span class="text-muted-foreground">Answered: </span>
        {response.text}
      </div>
    <% else %>
      <.question id="question-freeform" class="w-full max-w-2xl" on_submit="question_submit">
        <div class="space-y-1">
          <.question_prompt>What should we name the project?</.question_prompt>
          <.question_description>Enter a short, memorable name.</.question_description>
        </div>
        <.question_input aria-label="Project name" placeholder="Project name…" />
        <.question_actions>
          <.question_submit has_response="false">Answer</.question_submit>
        </.question_actions>
      </.question>
    <% end %>
    """
  end

  defp question_multi_select(assigns) do
    ~H"""
    <%= if response = @question_answers["multi-select"] do %>
      <div class="w-full max-w-2xl rounded-lg border bg-background p-4 text-sm">
        <span class="text-muted-foreground">Selected: </span>
        {Enum.join(response.selected_values, ", ")}
      </div>
    <% else %>
      <.question
        id="question-multi-select"
        class="w-full max-w-2xl"
        selection_mode="multiple"
        on_submit="question_submit"
      >
        <div class="space-y-1">
          <.question_prompt>Which features should we include?</.question_prompt>
          <.question_description>Select all that apply.</.question_description>
        </div>
        <.question_options selection_mode="multiple" aria-label="Features">
          <.question_option value="Authentication" role="checkbox" is_selected="false">
            Authentication
          </.question_option>
          <.question_option value="Database" role="checkbox" is_selected="false">
            Database
          </.question_option>
          <.question_option value="Payments" role="checkbox" is_selected="false">
            Payments
          </.question_option>
        </.question_options>
        <.question_actions>
          <.question_submit has_response="false">Continue</.question_submit>
        </.question_actions>
      </.question>
    <% end %>
    """
  end

  defp question_single_select(assigns) do
    ~H"""
    <%= if response = @question_answers["single-select"] do %>
      <div class="w-full max-w-2xl rounded-lg border bg-background p-4 text-sm">
        <span class="text-muted-foreground">Selected: </span>
        {List.first(response.selected_values)}
      </div>
    <% else %>
      <.question id="question-single-select" class="w-full max-w-2xl" on_submit="question_submit">
        <div class="space-y-1">
          <.question_prompt>Which framework should we use?</.question_prompt>
          <.question_description>Select one option.</.question_description>
        </div>
        <.question_options selection_mode="single" aria-label="Framework">
          <.question_option value="Next.js" role="radio" is_selected="false">
            Next.js
          </.question_option>
          <.question_option value="Nuxt" role="radio" is_selected="false">Nuxt</.question_option>
          <.question_option value="SvelteKit" role="radio" is_selected="false">
            SvelteKit
          </.question_option>
        </.question_options>
        <.question_actions>
          <.question_submit has_response="false">Continue</.question_submit>
        </.question_actions>
      </.question>
    <% end %>
    """
  end

  defp question_summary(%{selected_values: selected_values, text: text}) do
    [Enum.join(selected_values, ", "), text]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" — ")
  end

  defp questionnaire_default(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-default"
      class="mx-auto max-w-md"
      default_item="direction"
      shortcuts="letters"
    >
      <.questionnaire_progress />
      <.questionnaire_item name="direction" required>
        <.questionnaire_title>What should the agent build next?</.questionnaire_title>
        <.questionnaire_description>
          Choose a direction or describe another task.
        </.questionnaire_description>
        <.questionnaire_choices>
          <.questionnaire_choice value="tool-calls" name="direction">
            <span class="font-medium">Tool call timeline</span><span class="text-muted-foreground">Show what the agent ran and what came back.</span>
          </.questionnaire_choice>
          <.questionnaire_choice value="approvals" name="direction">
            <span class="font-medium">Approval checkpoints</span><span class="text-muted-foreground">Ask before sensitive or destructive actions.</span>
          </.questionnaire_choice>
          <.questionnaire_choice value="handoffs" name="direction">
            <span class="font-medium">Sub-agent handoffs</span><span class="text-muted-foreground">Make delegated work and results easier to follow.</span>
          </.questionnaire_choice>
          <.questionnaire_input
            name="direction"
            aria-label="Another agent feature"
            placeholder="Describe another feature…"
          />
        </.questionnaire_choices>
        <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
      </.questionnaire_item>
      <.questionnaire_item name="signals" multiple>
        <.questionnaire_title>What should every progress update include?</.questionnaire_title>
        <.questionnaire_description>
          Select all that apply, or skip this question.
        </.questionnaire_description>
        <.questionnaire_choices>
          <.questionnaire_choice value="progress" name="signals" type="checkbox">
            Progress
          </.questionnaire_choice><.questionnaire_choice
            value="decisions"
            name="signals"
            type="checkbox"
          >
            Decisions
          </.questionnaire_choice><.questionnaire_choice value="risks" name="signals" type="checkbox">
            Risks
          </.questionnaire_choice><.questionnaire_choice
            value="next-step"
            name="signals"
            type="checkbox"
          >
            Next step
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error>Choose an answer or skip this question.</.questionnaire_error>
      </.questionnaire_item>
      <.questionnaire_item name="timing" required>
        <.questionnaire_title>When should work begin?</.questionnaire_title>
        <.questionnaire_description>
          Choose when the agent should begin the work.
        </.questionnaire_description>
        <.questionnaire_choices>
          <.questionnaire_choice value="now" name="timing">Start now</.questionnaire_choice><.questionnaire_choice
            value="next-cycle"
            name="timing"
          >
            Next development cycle
          </.questionnaire_choice><.questionnaire_choice value="backlog" name="timing">
            Add it to the backlog
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_skip /><.questionnaire_next>
          Next
        </.questionnaire_next><.questionnaire_submit>Save plan</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_multiple(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-multiple"
      class="mx-auto max-w-md"
      default_item="context"
      shortcuts="letters"
    >
      <.questionnaire_item name="context" multiple required>
        <.questionnaire_title>What context should the agent inspect?</.questionnaire_title>
        <.questionnaire_description>
          Select every source that may affect the implementation.
        </.questionnaire_description>
        <.questionnaire_choices>
          <.questionnaire_choice value="source" name="context" type="checkbox">
            Relevant source files
          </.questionnaire_choice><.questionnaire_choice value="tests" name="context" type="checkbox">
            Existing tests
          </.questionnaire_choice><.questionnaire_choice value="docs" name="context" type="checkbox">
            Architecture documentation
          </.questionnaire_choice><.questionnaire_choice
            value="history"
            name="context"
            type="checkbox"
          >
            Recent commit history
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_submit>Share context</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_freeform(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-freeform"
      class="mx-auto max-w-md"
      default_item="approach"
      shortcuts="letters"
    >
      <.questionnaire_item name="approach" required>
        <.questionnaire_title>How should the agent approach this refactor?</.questionnaire_title><.questionnaire_description>
          Choose a strategy or write a more specific instruction.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="incremental" name="approach">
            Make the smallest safe change
          </.questionnaire_choice><.questionnaire_choice value="module" name="approach">
            Refactor one module at a time
          </.questionnaire_choice><.questionnaire_choice value="rewrite" name="approach">
            Replace the implementation completely
          </.questionnaire_choice><.questionnaire_input
            name="approach"
            aria-label="Another refactoring approach"
            placeholder="Describe another approach…"
          />
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_submit>Use this approach</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_skip_example(assigns) do
    ~H"""
    <.questionnaire id="questionnaire-skip" class="mx-auto max-w-md" default_item="task">
      <.questionnaire_progress /><.questionnaire_item name="task" required>
        <.questionnaire_title>What kind of change is this?</.questionnaire_title><.questionnaire_description>
          Choose the category that best describes the work.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="feature" name="task">New feature</.questionnaire_choice><.questionnaire_choice
            value="fix"
            name="task"
          >
            Bug fix
          </.questionnaire_choice><.questionnaire_choice value="refactor" name="task">
            Refactor
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="constraints">
        <.questionnaire_title>Are there any implementation constraints?</.questionnaire_title><.questionnaire_description>
          Answer if needed, or intentionally skip this question.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="no-dependencies" name="constraints">
            Do not add dependencies
          </.questionnaire_choice><.questionnaire_choice value="no-migrations" name="constraints">
            Do not change the database
          </.questionnaire_choice><.questionnaire_choice value="preserve-api" name="constraints">
            Preserve the public API
          </.questionnaire_choice><.questionnaire_input
            name="constraints"
            aria-label="Another implementation constraint"
            placeholder="Describe another constraint…"
          />
        </.questionnaire_choices>
      </.questionnaire_item><.questionnaire_item name="review" required>
        <.questionnaire_title>How should the work be reviewed?</.questionnaire_title><.questionnaire_description>
          Choose the checks the agent should complete before handoff.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="tests" name="review">
            Run the test suite
          </.questionnaire_choice><.questionnaire_choice value="diff" name="review">
            Review the final diff
          </.questionnaire_choice><.questionnaire_choice value="both" name="review">
            Tests and diff review
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_skip /><.questionnaire_next>
          Next
        </.questionnaire_next><.questionnaire_submit>Submit brief</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_shortcuts(assigns) do
    ~H"""
    <div class="relative mx-auto flex h-full w-full max-w-md flex-col">
      <.native_select
        form="questionnaire-shortcuts"
        name="shortcut_mode"
        aria-label="Shortcut style"
        class="absolute end-0 top-0"
        phx-change="questionnaire_shortcuts"
      >
        <.native_select_option value="none" selected={@questionnaire_shortcuts == "none"}>
          No shortcuts
        </.native_select_option><.native_select_option
          value="letters"
          selected={@questionnaire_shortcuts == "letters"}
        >
          Letters
        </.native_select_option><.native_select_option
          value="numbers"
          selected={@questionnaire_shortcuts == "numbers"}
        >
          Numbers
        </.native_select_option>
      </.native_select><.questionnaire
        id="questionnaire-shortcuts"
        class="mt-auto"
        default_item="action"
        items={[
          %{
            name: "action",
            required: true,
            choices: [%{value: "inspect"}, %{value: "tests"}, %{value: "patch"}]
          }
        ]}
        shortcuts={if(@questionnaire_shortcuts == "none", do: nil, else: @questionnaire_shortcuts)}
      >
        <.questionnaire_item name="action" required>
          <.questionnaire_title>What should the agent do next?</.questionnaire_title><.questionnaire_description>
            Use the displayed shortcut or navigate with the keyboard.
          </.questionnaire_description><.questionnaire_choices>
            <.questionnaire_choice value="inspect" name="action">
              Inspect the implementation
            </.questionnaire_choice><.questionnaire_choice value="tests" name="action">
              Run the relevant tests
            </.questionnaire_choice><.questionnaire_choice value="patch" name="action">
              Prepare the patch
            </.questionnaire_choice>
          </.questionnaire_choices><.questionnaire_error>
            Choose an answer to continue.
          </.questionnaire_error>
        </.questionnaire_item><.questionnaire_actions>
          <.questionnaire_submit>Confirm action</.questionnaire_submit>
        </.questionnaire_actions>
      </.questionnaire>
    </div>
    """
  end

  defp questionnaire_validation(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-validation"
      class="mx-auto max-w-md"
      item={@questionnaire_validation_item}
      items={[%{name: "detail", required: true}, %{name: "audience", required: true}]}
      on_item_change="questionnaire_validation_item"
      on_submit="questionnaire_validation_submit"
    >
      <.card class="w-full">
        <.questionnaire_item
          name="detail"
          required
          invalid={Map.has_key?(@questionnaire_validation_errors, "detail")}
        >
          <.card_header>
            <.questionnaire_title>How much detail should the answer include?</.questionnaire_title><.questionnaire_description>
              Choose the response depth.
            </.questionnaire_description><.card_action>
              <.questionnaire_progress class="min-w-0" format="fraction" current={1} total={2} />
            </.card_action>
          </.card_header><.card_content>
            <.questionnaire_choices>
              <.questionnaire_choice value="summary" name="detail">
                Concise summary
              </.questionnaire_choice><.questionnaire_choice value="complete" name="detail">
                Complete answer
              </.questionnaire_choice>
            </.questionnaire_choices><.questionnaire_error>
              {Map.get(@questionnaire_validation_errors, "detail", "Choose an answer to continue.")}
            </.questionnaire_error>
          </.card_content>
        </.questionnaire_item><.questionnaire_item
          name="audience"
          required
          invalid={Map.has_key?(@questionnaire_validation_errors, "audience")}
        >
          <.card_header>
            <.questionnaire_title>Who will read the answer?</.questionnaire_title><.questionnaire_description>
              Public answers require complete context.
            </.questionnaire_description><.card_action>
              <.questionnaire_progress class="min-w-0" format="fraction" current={1} total={2} />
            </.card_action>
          </.card_header><.card_content>
            <.questionnaire_choices>
              <.questionnaire_choice value="team" name="audience">My team</.questionnaire_choice><.questionnaire_choice
                value="public"
                name="audience"
              >
                Public audience
              </.questionnaire_choice>
            </.questionnaire_choices><.questionnaire_error>
              {Map.get(@questionnaire_validation_errors, "audience", "Choose an answer to continue.")}
            </.questionnaire_error>
          </.card_content>
        </.questionnaire_item><.card_footer>
          <.questionnaire_actions>
            <.questionnaire_previous /><.questionnaire_next>Next</.questionnaire_next><.questionnaire_submit>
              Validate answers
            </.questionnaire_submit>
          </.questionnaire_actions>
        </.card_footer>
      </.card>
    </.questionnaire>
    """
  end

  defp questionnaire_controlled(assigns) do
    ~H"""
    <div class="relative mx-auto flex h-full w-full max-w-md flex-col">
      <p class="absolute end-0 top-0 text-sm text-muted-foreground" role="status">
        Current checkpoint: <!-- -->
        {Map.fetch!(
          %{"scope" => "Change scope", "checks" => "Verification", "output" => "Final output"},
          @questionnaire_controlled_item
        )}
      </p><.questionnaire
        id="questionnaire-controlled"
        class="mt-auto"
        item={@questionnaire_controlled_item}
        items={[
          %{name: "scope", required: true},
          %{name: "checks", required: true},
          %{name: "output", required: true}
        ]}
        on_item_change="questionnaire_controlled_item"
        on_submit="questionnaire_controlled_submit"
      >
        <.questionnaire_progress /><.questionnaire_item name="scope" required>
          <.questionnaire_title>What may the agent change?</.questionnaire_title><.questionnaire_description>
            The host stores the active checkpoint while Questionnaire navigates.
          </.questionnaire_description><.questionnaire_choices>
            <.questionnaire_choice value="component" name="scope">
              Only the target component
            </.questionnaire_choice><.questionnaire_choice value="tests" name="scope">
              Component and related tests
            </.questionnaire_choice><.questionnaire_choice value="feature" name="scope">
              The complete feature area
            </.questionnaire_choice>
          </.questionnaire_choices><.questionnaire_error>
            Choose an answer to continue.
          </.questionnaire_error>
        </.questionnaire_item><.questionnaire_item name="checks" required>
          <.questionnaire_title>Which verification level should it use?</.questionnaire_title><.questionnaire_choices>
            <.questionnaire_choice value="targeted" name="checks">
              Targeted tests
            </.questionnaire_choice><.questionnaire_choice value="package" name="checks">
              Package tests and typecheck
            </.questionnaire_choice><.questionnaire_choice value="full" name="checks">
              Full workspace verification
            </.questionnaire_choice>
          </.questionnaire_choices><.questionnaire_error>
            Choose an answer to continue.
          </.questionnaire_error>
        </.questionnaire_item><.questionnaire_item name="output" required>
          <.questionnaire_title>What should the agent return when finished?</.questionnaire_title><.questionnaire_choices>
            <.questionnaire_choice value="summary" name="output">
              Concise summary
            </.questionnaire_choice><.questionnaire_choice value="diff" name="output">
              Summary with changed files
            </.questionnaire_choice><.questionnaire_choice value="handoff" name="output">
              Detailed implementation handoff
            </.questionnaire_choice>
          </.questionnaire_choices><.questionnaire_error>
            Choose an answer to continue.
          </.questionnaire_error>
        </.questionnaire_item><.questionnaire_actions>
          <.questionnaire_previous /><.questionnaire_next>Next</.questionnaire_next><.questionnaire_submit>
            Save workflow
          </.questionnaire_submit>
        </.questionnaire_actions>
      </.questionnaire>
    </div>
    """
  end

  defp questionnaire_resume(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-resume"
      class="mx-auto max-w-md"
      default_item="verification"
      items={[
        %{name: "change", required: true},
        %{name: "verification", required: true},
        %{name: "notes"}
      ]}
      on_reset="questionnaire_resume_reset"
    >
      <.questionnaire_progress /><.questionnaire_item name="change" required>
        <.questionnaire_title>What kind of migration is this?</.questionnaire_title><.questionnaire_description>
          This answer was saved during the previous session.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="incremental" name="change" default_checked>
            Incremental migration
          </.questionnaire_choice><.questionnaire_choice value="cutover" name="change">
            Single cutover
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="verification" multiple required>
        <.questionnaire_title>How should the migration be verified?</.questionnaire_title><.questionnaire_description>
          These checks were selected during the previous session.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="tests" name="verification" type="checkbox" default_checked>
            Run migration tests
          </.questionnaire_choice><.questionnaire_choice
            value="typecheck"
            name="verification"
            type="checkbox"
            default_checked
          >
            Run the typecheck
          </.questionnaire_choice><.questionnaire_choice
            value="manual"
            name="verification"
            type="checkbox"
          >
            Perform a manual smoke test
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="notes">
        <.questionnaire_title>Anything else the agent should remember?</.questionnaire_title><.questionnaire_description>
          This note was saved with the draft.
        </.questionnaire_description><.questionnaire_input
          name="notes"
          aria-label="Saved migration note"
          value="Keep the existing public API stable."
        />
      </.questionnaire_item><.questionnaire_actions>
        <.button type="reset" variant="outline">Reset changes</.button><.questionnaire_previous /><.questionnaire_next>
          Next
        </.questionnaire_next><.questionnaire_submit>Update draft</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_conditional(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-conditional"
      class="mx-auto max-w-md"
      default_item="runtime"
      items={[
        %{name: "runtime", required: true},
        %{name: "environment", required: true, disabled: @questionnaire_runtime != "cloud"},
        %{name: "approval", required: true}
      ]}
    >
      <.questionnaire_progress /><.questionnaire_item name="runtime" required>
        <.questionnaire_title>Where should the agent run?</.questionnaire_title><.questionnaire_description>
          Cloud runs add an environment question to this flow.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice
            value="local"
            name="runtime"
            checked={@questionnaire_runtime == "local"}
            on_change="questionnaire_runtime"
          >
            Local workspace
          </.questionnaire_choice><.questionnaire_choice
            value="cloud"
            name="runtime"
            checked={@questionnaire_runtime == "cloud"}
            on_change="questionnaire_runtime"
          >
            Cloud workspace
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item>
      <%= if @questionnaire_runtime == "cloud" do %>
        <.questionnaire_item name="environment" required>
          <.questionnaire_title>Which cloud environment should it use?</.questionnaire_title><.questionnaire_choices>
            <.questionnaire_choice value="preview" name="environment">Preview</.questionnaire_choice><.questionnaire_choice
              value="staging"
              name="environment"
            >
              Staging
            </.questionnaire_choice><.questionnaire_choice value="isolated" name="environment">
              Isolated sandbox
            </.questionnaire_choice>
          </.questionnaire_choices><.questionnaire_error>
            Choose an answer to continue.
          </.questionnaire_error>
        </.questionnaire_item>
      <% end %>
      <.questionnaire_item name="approval" required>
        <.questionnaire_title>When should the agent request approval?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="writes" name="approval">
            Before writing files
          </.questionnaire_choice><.questionnaire_choice value="commands" name="approval">
            Before running commands
          </.questionnaire_choice><.questionnaire_choice value="sensitive" name="approval">
            Only for sensitive actions
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_next>Next</.questionnaire_next><.questionnaire_submit>
          Save execution plan
        </.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_navigation_state(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-navigation-state"
      class="mx-auto max-w-md"
      item={@questionnaire_navigation_item}
      items={[%{name: "permission", required: true}, %{name: "verification", required: true}]}
      on_item_change="questionnaire_navigation_item"
    >
      <.questionnaire_progress /><.questionnaire_item
        name="permission"
        required
        on_status_change="questionnaire_navigation_status"
      >
        <.questionnaire_title>What may the agent modify?</.questionnaire_title><.questionnaire_description>
          Next is intentionally disabled until an answer is selected.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="files" name="permission">Project files</.questionnaire_choice><.questionnaire_choice
            value="tests"
            name="permission"
          >
            Project files and tests
          </.questionnaire_choice><.questionnaire_choice value="config" name="permission">
            Files, tests, and configuration
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item
        name="verification"
        required
        on_status_change="questionnaire_navigation_status"
      >
        <.questionnaire_title>What must pass before completion?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="tests" name="verification">Tests</.questionnaire_choice><.questionnaire_choice
            value="types"
            name="verification"
          >
            Tests and types
          </.questionnaire_choice><.questionnaire_choice value="all" name="verification">
            Tests, types, and visual QA
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_next
          class="data-[status=unanswered]:opacity-50"
          data-lb-disable-unanswered
          disabled={
            @questionnaire_navigation_statuses[@questionnaire_navigation_item] == "unanswered"
          }
          variant="secondary"
        >
          Next
        </.questionnaire_next><.questionnaire_submit
          data-lb-disable-unanswered
          disabled={
            @questionnaire_navigation_statuses[@questionnaire_navigation_item] == "unanswered"
          }
        >
          Save permissions
        </.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_progress_example(assigns) do
    ~H"""
    <.questionnaire id="questionnaire-progress" class="mx-auto max-w-md" default_item="scope">
      <.questionnaire_progress class="w-full" format="checkpoint" current={1} total={4} /><.questionnaire_item
        name="scope"
        required
      >
        <.questionnaire_title>How large is the change?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="small" name="scope">Small patch</.questionnaire_choice><.questionnaire_choice
            value="medium"
            name="scope"
          >
            Feature-sized change
          </.questionnaire_choice><.questionnaire_choice value="large" name="scope">
            Cross-package change
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="strategy" required>
        <.questionnaire_title>How should commits be organized?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="single" name="strategy">Single commit</.questionnaire_choice><.questionnaire_choice
            value="logical"
            name="strategy"
          >
            Logical commits
          </.questionnaire_choice><.questionnaire_choice value="squash" name="strategy">
            Squash before review
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="tests" required>
        <.questionnaire_title>Which tests should run?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="targeted" name="tests">Targeted tests</.questionnaire_choice><.questionnaire_choice
            value="package"
            name="tests"
          >
            Package suite
          </.questionnaire_choice><.questionnaire_choice value="workspace" name="tests">
            Full workspace
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item name="delivery" required>
        <.questionnaire_title>How should the work be delivered?</.questionnaire_title><.questionnaire_choices>
          <.questionnaire_choice value="patch" name="delivery">Patch only</.questionnaire_choice><.questionnaire_choice
            value="commit"
            name="delivery"
          >
            Committed locally
          </.questionnaire_choice><.questionnaire_choice value="branch" name="delivery">
            Push a review branch
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_next>Next</.questionnaire_next><.questionnaire_submit>
          Finish plan
        </.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_animated(assigns) do
    ~H"""
    <.questionnaire id="questionnaire-animated" class="mx-auto max-w-md" default_item="task">
      <.questionnaire_progress /><.questionnaire_item
        class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
        name="task"
        required
      >
        <.questionnaire_title>What should the agent do?</.questionnaire_title><.questionnaire_description>
          Choose the task for this run.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="implement" name="task">
            Implement the requested change
          </.questionnaire_choice><.questionnaire_choice value="debug" name="task">
            Debug the current behavior
          </.questionnaire_choice><.questionnaire_choice value="review" name="task">
            Review the implementation
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item
        class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
        name="review"
        required
      >
        <.questionnaire_title>How should the work be reviewed?</.questionnaire_title><.questionnaire_description>
          Select the verification depth.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="targeted" name="review">
            Targeted checks
          </.questionnaire_choice><.questionnaire_choice value="complete" name="review">
            Complete test suite
          </.questionnaire_choice><.questionnaire_choice value="manual" name="review">
            Tests and manual QA
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_item
        class="data-active:animate-in data-active:fade-in-0 data-active:slide-in-from-bottom-2 data-active:duration-300 motion-reduce:animate-none"
        name="delivery"
        required
      >
        <.questionnaire_title>How should the result be delivered?</.questionnaire_title><.questionnaire_description>
          Choose the final handoff format.
        </.questionnaire_description><.questionnaire_choices>
          <.questionnaire_choice value="summary" name="delivery">
            Concise summary
          </.questionnaire_choice><.questionnaire_choice value="diff" name="delivery">
            Summary and changed files
          </.questionnaire_choice><.questionnaire_choice value="handoff" name="delivery">
            Detailed review handoff
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_error>
          Choose an answer to continue.
        </.questionnaire_error>
      </.questionnaire_item><.questionnaire_actions>
        <.questionnaire_previous /><.questionnaire_next>Next</.questionnaire_next><.questionnaire_submit>
          Save workflow
        </.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  defp questionnaire_card(assigns) do
    ~H"""
    <.questionnaire
      id="questionnaire-card"
      class="mx-auto max-w-md"
      default_item="task"
      items={[
        %{
          name: "task",
          required: true,
          choices: [%{value: "fix"}, %{value: "refactor"}, %{value: "docs"}]
        },
        %{
          name: "output",
          required: true,
          choices: [%{value: "summary"}, %{value: "files"}, %{value: "review"}]
        }
      ]}
      shortcuts="numbers"
      on_submit="questionnaire_card_submit"
    >
      <.card>
        <.questionnaire_item name="task" required aria-labelledby="questionnaire-card-task-title">
          <.card_header>
            <div
              id="questionnaire-card-task-title"
              data-slot="questionnaire-title"
              class="cn-card-title cn-font-heading cn-questionnaire-title cn-font-heading text-pretty"
            >
              What should the agent work on?
            </div>
            <div
              data-slot="questionnaire-description"
              class="cn-card-description cn-questionnaire-description text-pretty text-muted-foreground"
            >
              Choose the task that should be handled next.
            </div>
            <.card_action><.questionnaire_progress /></.card_action>
          </.card_header>
          <.card_content>
            <.questionnaire_choices>
              <.questionnaire_choice value="fix" name="task">
                Fix the failing tests
              </.questionnaire_choice>
              <.questionnaire_choice value="refactor" name="task">
                Refactor the data layer
              </.questionnaire_choice>
              <.questionnaire_choice value="docs" name="task">
                Update the integration guide
              </.questionnaire_choice>
            </.questionnaire_choices>
            <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
          </.card_content>
        </.questionnaire_item>
        <.questionnaire_item name="output" required aria-labelledby="questionnaire-card-output-title">
          <.card_header>
            <div
              id="questionnaire-card-output-title"
              data-slot="questionnaire-title"
              class="cn-card-title cn-font-heading cn-questionnaire-title cn-font-heading text-pretty"
            >
              What should the final handoff include?
            </div>
            <div
              data-slot="questionnaire-description"
              class="cn-card-description cn-questionnaire-description text-pretty text-muted-foreground"
            >
              Pick the level of detail needed for review.
            </div>
            <.card_action><.questionnaire_progress /></.card_action>
          </.card_header>
          <.card_content>
            <.questionnaire_choices>
              <.questionnaire_choice value="summary" name="output">
                Summary only
              </.questionnaire_choice>
              <.questionnaire_choice value="files" name="output">
                Summary and changed files
              </.questionnaire_choice>
              <.questionnaire_choice value="review" name="output">
                Full review handoff
              </.questionnaire_choice>
            </.questionnaire_choices>
            <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
          </.card_content>
        </.questionnaire_item>
        <.card_footer>
          <.questionnaire_actions class="w-full">
            <.questionnaire_previous />
            <.questionnaire_next>Next</.questionnaire_next>
            <.questionnaire_submit>Create task</.questionnaire_submit>
          </.questionnaire_actions>
        </.card_footer>
      </.card>
    </.questionnaire>
    """
  end

  defp questionnaire_dialog(assigns) do
    ~H"""
    <.dialog id="questionnaire-dialog" trigger_variant="outline">
      <:trigger>Open clarification</:trigger>
      <.questionnaire
        id="questionnaire-dialog"
        default_item="scope"
        items={[%{name: "scope", required: true}, %{name: "tests", required: true}]}
        on_submit="questionnaire_dialog_submit"
        data-lb-close-dialog-on-submit="questionnaire-dialog"
        data-lb-reset-on-dialog-close
      >
        <.questionnaire_item name="scope" required>
          <div data-slot="dialog-header" class="cn-dialog-header flex flex-col">
            <.questionnaire_progress />
            <h2
              id="questionnaire-dialog-scope-title"
              data-slot="questionnaire-title"
              class="cn-dialog-title cn-font-heading cn-questionnaire-title text-pretty"
            >
              Which files are in scope?
            </h2>
            <p
              id="questionnaire-dialog-scope-description"
              data-slot="questionnaire-description"
              class="cn-dialog-description cn-questionnaire-description text-pretty text-muted-foreground"
            >
              Choose how broadly the agent can update the workspace.
            </p>
          </div>
          <.questionnaire_choices>
            <.questionnaire_choice value="component" name="scope">
              Component only
            </.questionnaire_choice>
            <.questionnaire_choice value="feature" name="scope">
              Complete feature directory
            </.questionnaire_choice>
            <.questionnaire_choice value="workspace" name="scope">
              Any related workspace file
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
        </.questionnaire_item>
        <.questionnaire_item name="tests" required>
          <div data-slot="dialog-header" class="cn-dialog-header flex flex-col">
            <.questionnaire_progress />
            <h2
              id="questionnaire-dialog-tests-title"
              data-slot="questionnaire-title"
              class="cn-dialog-title cn-font-heading cn-questionnaire-title text-pretty"
            >
              How much verification is needed?
            </h2>
            <p
              id="questionnaire-dialog-tests-description"
              data-slot="questionnaire-description"
              class="cn-dialog-description cn-questionnaire-description text-pretty text-muted-foreground"
            >
              Choose the checks the agent should run before handoff.
            </p>
          </div>
          <.questionnaire_choices>
            <.questionnaire_choice value="targeted" name="tests">
              Targeted tests
            </.questionnaire_choice>
            <.questionnaire_choice value="package" name="tests">Package tests</.questionnaire_choice>
            <.questionnaire_choice value="full" name="tests">
              Full workspace verification
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error>Choose an answer to continue.</.questionnaire_error>
        </.questionnaire_item>
        <div
          data-slot="dialog-footer"
          class="cn-dialog-footer flex flex-col-reverse gap-2 sm:flex-row sm:justify-end"
        >
          <.button
            data-slot="dialog-close"
            type="button"
            variant="outline"
            phx-click={LiveBase.Dialog.close("questionnaire-dialog")}
          >Cancel</.button>
          <.questionnaire_actions>
            <.questionnaire_previous />
            <.questionnaire_next>Next</.questionnaire_next>
            <.questionnaire_submit>Send answer</.questionnaire_submit>
          </.questionnaire_actions>
        </div>
      </.questionnaire>
    </.dialog>
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
    assigns =
      assign(assigns,
        checkout: %{
          class: "w-full max-w-md",
          dir: nil,
          suffix: "",
          payment_method: "Payment Method",
          secure_transactions: "All transactions are secure and encrypted",
          name_on_card: "Name on Card",
          card_number: "Card Number",
          card_number_description: "Enter your 16-digit card number",
          month: "Month",
          year: "Year",
          cvv: "CVV",
          billing_address: "Billing Address",
          billing_address_description: "The billing address associated with your payment method",
          same_as_shipping: "Same as shipping address",
          comments: "Comments",
          comments_placeholder: "Add any additional comments",
          submit: "Submit",
          cancel: "Cancel"
        },
        months: @field_months,
        years: @field_years
      )

    field_checkout(assigns)
  end

  defp field_input(assigns) do
    ~H"""
    <.field_set class="w-full max-w-xs">
      <.field_group>
        <.field>
          <.field_label for="username">Username</.field_label>
          <.input id="username" type="text" placeholder="Max Leiter" />
          <.field_description>Choose a unique username for your account.</.field_description>
        </.field>
        <.field>
          <.field_label for="password">Password</.field_label>
          <.field_description>Must be at least 8 characters long.</.field_description>
          <.input id="password" type="password" placeholder="••••••••" />
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  defp field_textarea(assigns) do
    ~H"""
    <.field_set class="w-full max-w-xs">
      <.field_group>
        <.field>
          <.field_label for="feedback">Feedback</.field_label>
          <.textarea
            id="feedback"
            placeholder="Your feedback helps us improve..."
            rows="4"
          />
          <.field_description>Share your thoughts about our service.</.field_description>
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  defp field_select(assigns) do
    assigns =
      assign(assigns, :options, [
        %{label: "Choose department", value: ""},
        %{label: "Engineering", value: "engineering"},
        %{label: "Design", value: "design"},
        %{label: "Marketing", value: "marketing"},
        %{label: "Sales", value: "sales"},
        %{label: "Customer Support", value: "support"},
        %{label: "Human Resources", value: "hr"},
        %{label: "Finance", value: "finance"},
        %{label: "Operations", value: "operations"}
      ])

    ~H"""
    <.field class="w-full max-w-xs">
      <.field_label>Department</.field_label>
      <.select id="department">
        <:group options={@options} />
      </.select>
      <.field_description>Select your department or area of work.</.field_description>
    </.field>
    """
  end

  defp field_slider(assigns) do
    ~H"""
    <.field class="w-full max-w-xs">
      <.field_title>Price Range</.field_title>
      <.field_description>
        Set your budget range ($<span class="font-medium tabular-nums">{@field_slider_values
        |> List.first()}</span>
        - <span class="font-medium tabular-nums">{@field_slider_values |> List.last()}</span>).
      </.field_description>
      <.slider
        id="field-price-range"
        value={@field_slider_values}
        min={0}
        max={1000}
        step={10}
        label="Price Range"
        on_change="field_slider_value"
        class="mt-2 w-full"
      />
    </.field>
    """
  end

  defp field_fieldset(assigns) do
    ~H"""
    <.field_set class="w-full max-w-sm">
      <.field_legend>Address Information</.field_legend>
      <.field_description>We need your address to deliver your order.</.field_description>
      <.field_group>
        <.field>
          <.field_label for="street">Street Address</.field_label>
          <.input id="street" type="text" placeholder="123 Main St" />
        </.field>
        <div class="grid grid-cols-2 gap-4">
          <.field>
            <.field_label for="city">City</.field_label>
            <.input id="city" type="text" placeholder="New York" />
          </.field>
          <.field>
            <.field_label for="zip">Postal Code</.field_label>
            <.input id="zip" type="text" placeholder="90502" />
          </.field>
        </div>
      </.field_group>
    </.field_set>
    """
  end

  defp field_radio(assigns) do
    ~H"""
    <.field_set class="w-full max-w-xs">
      <.field_legend variant="label">Subscription Plan</.field_legend>
      <.field_description>Yearly and lifetime plans offer significant savings.</.field_description>
      <.radio_group id="field-subscription-plan">
        <.field orientation="horizontal">
          <.radio_group_item
            id="plan-monthly"
            group="field-subscription-plan"
            value="monthly"
            checked
          />
          <.field_label for="plan-monthly" class="font-normal">
            Monthly ($9.99/month)
          </.field_label>
        </.field>
        <.field orientation="horizontal">
          <.radio_group_item id="plan-yearly" group="field-subscription-plan" value="yearly" />
          <.field_label for="plan-yearly" class="font-normal">
            Yearly ($99.99/year)
          </.field_label>
        </.field>
        <.field orientation="horizontal">
          <.radio_group_item
            id="plan-lifetime"
            group="field-subscription-plan"
            value="lifetime"
          />
          <.field_label for="plan-lifetime" class="font-normal">
            Lifetime ($299.99)
          </.field_label>
        </.field>
      </.radio_group>
    </.field_set>
    """
  end

  defp field_switch(assigns) do
    ~H"""
    <.field orientation="horizontal" class="w-fit">
      <.field_label for="2fa">Multi-factor authentication</.field_label>
      <.switch
        id="2fa"
        checked={@field_switch_checked}
        on_toggle="field_switch_toggle"
      />
    </.field>
    """
  end

  defp field_checkbox(assigns) do
    ~H"""
    <.field_group class="w-full max-w-xs">
      <.field_set>
        <.field_legend variant="label">Show these items on the desktop</.field_legend>
        <.field_description>Select the items you want to show on the desktop.</.field_description>
        <.field_group class="gap-3">
          <.field orientation="horizontal">
            <.checkbox id="finder-pref-9k2-hard-disks-ljj" />
            <.field_label for="finder-pref-9k2-hard-disks-ljj" class="font-normal">
              Hard disks
            </.field_label>
          </.field>
          <.field orientation="horizontal">
            <.checkbox id="finder-pref-9k2-external-disks-1yg" />
            <.field_label for="finder-pref-9k2-external-disks-1yg" class="font-normal">
              External disks
            </.field_label>
          </.field>
          <.field orientation="horizontal">
            <.checkbox id="finder-pref-9k2-cds-dvds-fzt" />
            <.field_label for="finder-pref-9k2-cds-dvds-fzt" class="font-normal">
              CDs, DVDs, and iPods
            </.field_label>
          </.field>
          <.field orientation="horizontal">
            <.checkbox id="finder-pref-9k2-connected-servers-6l2" />
            <.field_label for="finder-pref-9k2-connected-servers-6l2" class="font-normal">
              Connected servers
            </.field_label>
          </.field>
        </.field_group>
      </.field_set>
      <.field_separator />
      <.field orientation="horizontal">
        <.checkbox id="finder-pref-9k2-sync-folders-nep" checked />
        <.field_content>
          <.field_label for="finder-pref-9k2-sync-folders-nep">
            Sync Desktop & Documents folders
          </.field_label>
          <.field_description>
            Your Desktop & Documents folders are being synced with iCloud Drive. You can access them from other devices.
          </.field_description>
        </.field_content>
      </.field>
    </.field_group>
    """
  end

  defp field_choice_card(assigns) do
    ~H"""
    <.field_group class="w-full max-w-xs">
      <.field_set>
        <.field_legend variant="label">Compute Environment</.field_legend>
        <.field_description>Select the compute environment for your cluster.</.field_description>
        <.radio_group id="field-compute-environment">
          <.field_label for="kubernetes-r2h">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Kubernetes</.field_title>
                <.field_description>Run GPU workloads on a K8s cluster.</.field_description>
              </.field_content>
              <.radio_group_item
                id="kubernetes-r2h"
                group="field-compute-environment"
                value="kubernetes"
                checked
              />
            </.field>
          </.field_label>
          <.field_label for="vm-z4k">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Virtual Machine</.field_title>
                <.field_description>Access a cluster to run GPU workloads.</.field_description>
              </.field_content>
              <.radio_group_item id="vm-z4k" group="field-compute-environment" value="vm" />
            </.field>
          </.field_label>
        </.radio_group>
      </.field_set>
    </.field_group>
    """
  end

  defp field_group_example(assigns) do
    ~H"""
    <.field_group class="w-full max-w-xs">
      <.field_set>
        <.field_label>Responses</.field_label>
        <.field_description>
          Get notified when ChatGPT responds to requests that take time, like research or image generation.
        </.field_description>
        <.field_group data-slot="checkbox-group">
          <.field orientation="horizontal">
            <.checkbox id="push" checked disabled />
            <.field_label for="push" class="font-normal">Push notifications</.field_label>
          </.field>
        </.field_group>
      </.field_set>
      <.field_separator />
      <.field_set>
        <.field_label>Tasks</.field_label>
        <.field_description>
          Get notified when tasks you've created have updates.<!-- -->
          <a href="#">Manage tasks</a>
        </.field_description>
        <.field_group data-slot="checkbox-group">
          <.field orientation="horizontal">
            <.checkbox id="push-tasks" />
            <.field_label for="push-tasks" class="font-normal">Push notifications</.field_label>
          </.field>
          <.field orientation="horizontal">
            <.checkbox id="email-tasks" />
            <.field_label for="email-tasks" class="font-normal">Email notifications</.field_label>
          </.field>
        </.field_group>
      </.field_set>
    </.field_group>
    """
  end

  defp field_rtl(assigns) do
    months = [
      %{label: "ش.ش", trigger_label: "MM", value: ""},
      %{label: "٠١", value: "01"},
      %{label: "٠٢", value: "02"},
      %{label: "٠٣", value: "03"},
      %{label: "٠٤", value: "04"},
      %{label: "٠٥", value: "05"},
      %{label: "٠٦", value: "06"},
      %{label: "٠٧", value: "07"},
      %{label: "٠٨", value: "08"},
      %{label: "٠٩", value: "09"},
      %{label: "١٠", value: "10"},
      %{label: "١١", value: "11"},
      %{label: "١٢", value: "12"}
    ]

    assigns =
      assign(assigns,
        checkout: %{
          class: "w-full max-w-md py-6",
          dir: "rtl",
          suffix: "-rtl",
          payment_method: "طريقة الدفع",
          secure_transactions: "جميع المعاملات آمنة ومشفرة",
          name_on_card: "الاسم على البطاقة",
          card_number: "رقم البطاقة",
          card_number_description: "أدخل رقم البطاقة المكون من 16 رقمًا",
          month: "الشهر",
          year: "السنة",
          cvv: "CVV",
          billing_address: "عنوان الفوترة",
          billing_address_description: "عنوان الفوترة المرتبط بطريقة الدفع الخاصة بك",
          same_as_shipping: "نفس عنوان الشحن",
          comments: "تعليقات",
          comments_placeholder: "أضف أي تعليقات إضافية",
          submit: "إرسال",
          cancel: "إلغاء"
        },
        months: months,
        years: @field_years
      )

    field_checkout(assigns)
  end

  defp field_responsive(assigns) do
    ~H"""
    <div class="w-full max-w-lg">
      <form>
        <.field_set>
          <.field_legend>Profile</.field_legend>
          <.field_description>Fill in your profile information.</.field_description>
          <.field_group>
            <.field orientation="responsive">
              <.field_content>
                <.field_label for="name">Name</.field_label>
                <.field_description>Provide your full name for identification</.field_description>
              </.field_content>
              <.input id="name" placeholder="Evil Rabbit" required />
            </.field>
            <.field orientation="responsive">
              <.button type="submit">Submit</.button>
              <.button type="button" variant="outline">Cancel</.button>
            </.field>
          </.field_group>
        </.field_set>
      </form>
    </div>
    """
  end

  defp field_checkout(assigns) do
    ~H"""
    <div class={@checkout.class} dir={@checkout.dir}>
      <form>
        <.field_group>
          <.field_set>
            <.field_legend>{@checkout.payment_method}</.field_legend>
            <.field_description>{@checkout.secure_transactions}</.field_description>
            <.field_group>
              <.field>
                <.field_label for={"checkout-7j9-card-name-43j#{@checkout.suffix}"}>
                  {@checkout.name_on_card}
                </.field_label>
                <.input
                  id={"checkout-7j9-card-name-43j#{@checkout.suffix}"}
                  placeholder="Evil Rabbit"
                  required
                />
              </.field>
              <.field>
                <.field_label for={"checkout-7j9-card-number-uw1#{@checkout.suffix}"}>
                  {@checkout.card_number}
                </.field_label>
                <.input
                  id={"checkout-7j9-card-number-uw1#{@checkout.suffix}"}
                  placeholder="1234 5678 9012 3456"
                  required
                />
                <.field_description>{@checkout.card_number_description}</.field_description>
              </.field>
              <div class="grid grid-cols-3 gap-4">
                <.field>
                  <.field_label for={"checkout-exp-month-ts6#{@checkout.suffix}"}>
                    {@checkout.month}
                  </.field_label>
                  <.select
                    id={"checkout-exp-month-ts6#{@checkout.suffix}"}
                    labelledby={"checkout-exp-month-ts6#{@checkout.suffix}-label"}
                    dir={@checkout.dir}
                  >
                    <:group options={@months} />
                  </.select>
                </.field>
                <.field>
                  <.field_label for={"checkout-7j9-exp-year-f59#{@checkout.suffix}"}>
                    {@checkout.year}
                  </.field_label>
                  <.select
                    id={"checkout-7j9-exp-year-f59#{@checkout.suffix}"}
                    labelledby={"checkout-7j9-exp-year-f59#{@checkout.suffix}-label"}
                    dir={@checkout.dir}
                  >
                    <:group options={@years} />
                  </.select>
                </.field>
                <.field>
                  <.field_label for={"checkout-7j9-cvv#{@checkout.suffix}"}>
                    {@checkout.cvv}
                  </.field_label>
                  <.input
                    id={"checkout-7j9-cvv#{@checkout.suffix}"}
                    placeholder="123"
                    required
                  />
                </.field>
              </div>
            </.field_group>
          </.field_set>
          <.field_separator />
          <.field_set>
            <.field_legend>{@checkout.billing_address}</.field_legend>
            <.field_description>{@checkout.billing_address_description}</.field_description>
            <.field_group>
              <.field orientation="horizontal">
                <.checkbox id={"checkout-7j9-same-as-shipping-wgm#{@checkout.suffix}"} checked />
                <.field_label
                  for={"checkout-7j9-same-as-shipping-wgm#{@checkout.suffix}"}
                  class="font-normal"
                >
                  {@checkout.same_as_shipping}
                </.field_label>
              </.field>
            </.field_group>
          </.field_set>
          <.field_set>
            <.field_group>
              <.field>
                <.field_label for={"checkout-7j9-optional-comments#{@checkout.suffix}"}>
                  {@checkout.comments}
                </.field_label>
                <.textarea
                  id={"checkout-7j9-optional-comments#{@checkout.suffix}"}
                  placeholder={@checkout.comments_placeholder}
                  class="resize-none"
                />
              </.field>
            </.field_group>
          </.field_set>
          <.field orientation="horizontal">
            <.button type="submit">{@checkout.submit}</.button>
            <.button variant="outline" type="button">{@checkout.cancel}</.button>
          </.field>
        </.field_group>
      </form>
    </div>
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
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-default">
      <.combobox_input combobox_id={combobox.id} combobox={combobox} placeholder="Select a framework" />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-default">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-default"
            value={framework}
            label={framework}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_basic(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-basic">
      <.combobox_input combobox_id={combobox.id} combobox={combobox} placeholder="Select a framework" />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-basic">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-basic"
            value={framework}
            label={framework}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_multiple(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox
      :let={combobox}
      id="combobox-multiple"
      multiple
      auto_highlight
      default_value={[hd(@combobox_frameworks)]}
    >
      <.combobox_chips id="combobox-multiple-chips" combobox={combobox} class="w-full max-w-xs">
        <.combobox_chip :for={value <- combobox.values} value={value}>{value}</.combobox_chip>
        <.combobox_chips_input combobox_id={combobox.id} combobox={combobox} />
      </.combobox_chips>
      <.combobox_content
        combobox_id={combobox.id}
        combobox={combobox}
        anchor="combobox-multiple-chips"
      >
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-multiple" multiple>
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-multiple"
            value={framework}
            label={framework}
            selected={framework in combobox.values}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_clear_example(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-clear" default_value={hd(@combobox_frameworks)}>
      <.combobox_input
        combobox_id={combobox.id}
        combobox={combobox}
        placeholder="Select a framework"
        value={Enum.find(@combobox_frameworks, &(&1 in combobox.values))}
        show_clear
      />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-clear">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-clear"
            value={framework}
            label={framework}
            selected={framework in combobox.values}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_groups(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-groups">
      <.combobox_input combobox_id={combobox.id} combobox={combobox} placeholder="Select a timezone" />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No timezones found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-groups">
          <.combobox_group
            :for={{group, index} <- Enum.with_index(@combobox_timezones)}
            combobox_id="combobox-groups"
            label={group.label}
          >
            <.combobox_collection>
              <.combobox_item
                :for={timezone <- group.items}
                combobox_id="combobox-groups"
                value={timezone}
                label={timezone}
              >
                {timezone}
              </.combobox_item>
            </.combobox_collection>
            <.combobox_separator :if={index < length(@combobox_timezones) - 1} />
          </.combobox_group>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_custom(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-custom">
      <.combobox_input
        combobox_id={combobox.id}
        combobox={combobox}
        placeholder="Search countries..."
      />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No countries found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-custom">
          <.combobox_item
            :for={country <- Enum.reject(@combobox_countries, &(&1.code == ""))}
            combobox_id="combobox-custom"
            value={country.value}
            label={country.label}
          >
            <.item size="xs" class="p-0">
              <.item_content>
                <.item_title class="whitespace-nowrap">{country.label}</.item_title>
                <.item_description>
                  {country.continent} ({country.code}<span>)</span>
                </.item_description>
              </.item_content>
            </.item>
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_invalid(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-invalid">
      <.combobox_input
        combobox_id={combobox.id}
        combobox={combobox}
        placeholder="Select a framework"
        aria-invalid="true"
      />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-invalid">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-invalid"
            value={framework}
            label={framework}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_disabled(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-disabled">
      <.combobox_input
        combobox_id={combobox.id}
        combobox={combobox}
        placeholder="Select a framework"
        disabled
      />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-disabled">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-disabled"
            value={framework}
            label={framework}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_auto_highlight(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-auto-highlight" auto_highlight>
      <.combobox_input combobox_id={combobox.id} combobox={combobox} placeholder="Select a framework" />
      <.combobox_content combobox_id={combobox.id} combobox={combobox}>
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-auto-highlight">
          <.combobox_item
            :for={framework <- @combobox_frameworks}
            combobox_id="combobox-auto-highlight"
            value={framework}
            label={framework}
          >
            {framework}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_popup(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-popup" default_value="">
      <.combobox_trigger
        combobox_id={combobox.id}
        combobox={combobox}
        class={
          LiveShadcn.UI.Button.button_class(
            variant: "outline",
            class: "w-64 justify-between font-normal"
          )
        }
      >
        <.combobox_value>Select country</.combobox_value>
      </.combobox_trigger>
      <.combobox_content
        combobox_id={combobox.id}
        combobox={combobox}
        input_in_popup
      >
        <.combobox_input
          combobox_id={combobox.id}
          combobox={combobox}
          controller={false}
          show_trigger={false}
          placeholder="Search"
        />
        <.combobox_empty>No items found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-popup">
          <.combobox_item
            :for={country <- @combobox_countries}
            combobox_id="combobox-popup"
            value={country.value}
            label={country.label}
          >
            {country.label}
          </.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_input_group(assigns) do
    assigns = assign_combobox_example_data(assigns)

    ~H"""
    <.combobox :let={combobox} id="combobox-input-group">
      <.combobox_input combobox_id={combobox.id} combobox={combobox} placeholder="Select a timezone">
        <.input_group_addon><LiveShadcn.Icon.icon name="globe" /></.input_group_addon>
      </.combobox_input>
      <.combobox_content combobox_id={combobox.id} combobox={combobox} align_offset={-28} class="w-60">
        <.combobox_empty>No timezones found.</.combobox_empty>
        <.combobox_list combobox_id="combobox-input-group">
          <.combobox_group
            :for={group <- @combobox_timezones}
            combobox_id="combobox-input-group"
            label={group.label}
          >
            <.combobox_collection>
              <.combobox_item
                :for={timezone <- group.items}
                combobox_id="combobox-input-group"
                value={timezone}
                label={timezone}
              >
                {timezone}
              </.combobox_item>
            </.combobox_collection>
          </.combobox_group>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  defp combobox_rtl(assigns) do
    assigns = assign_combobox_example_data(assigns)

    labels = %{
      "technology" => "التكنولوجيا",
      "design" => "التصميم",
      "business" => "الأعمال",
      "marketing" => "التسويق",
      "education" => "التعليم",
      "health" => "الصحة"
    }

    assigns = assign(assigns, :combobox_rtl_labels, labels)

    ~H"""
    <.field class="mx-auto w-full max-w-xs">
      <.field_label
        data-combobox-label-for="combobox-rtl"
        phx-mounted={LiveBase.Combobox.owned_attributes(:label)}
      >
        الفئات
      </.field_label>
      <.combobox
        :let={combobox}
        id="combobox-rtl"
        multiple
        auto_highlight
        default_value={["technology"]}
      >
        <.combobox_chips id="combobox-rtl-chips" combobox={combobox}>
          <.combobox_chip :for={value <- combobox.values} value={value}>
            {@combobox_rtl_labels[value] || value}
          </.combobox_chip>
          <.combobox_chips_input
            combobox_id={combobox.id}
            combobox={combobox}
            placeholder="أضف فئات"
          />
        </.combobox_chips>
        <.combobox_content
          combobox_id={combobox.id}
          combobox={combobox}
          anchor="combobox-rtl-chips"
          dir="rtl"
          data-lang="ar"
        >
          <.combobox_empty>لم يتم العثور على فئات.</.combobox_empty>
          <.combobox_list combobox_id="combobox-rtl" multiple>
            <.combobox_item
              :for={value <- @combobox_rtl_categories}
              combobox_id="combobox-rtl"
              value={value}
              label={@combobox_rtl_labels[value]}
              selected={value in combobox.values}
            >
              {@combobox_rtl_labels[value]}
            </.combobox_item>
          </.combobox_list>
        </.combobox_content>
      </.combobox>
    </.field>
    """
  end

  defp context_menu_target_class do
    "flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm"
  end

  attr(:fine, :string, required: true)
  attr(:coarse, :string, required: true)

  defp context_menu_target(assigns) do
    ~H"""
    <span class="hidden pointer-fine:inline-block">{@fine}</span>
    <span class="hidden pointer-coarse:inline-block">{@coarse}</span>
    """
  end

  defp context_menu_demo(assigns) do
    assigns =
      assign(assigns, :more_tools, [
        %{kind: "item", value: "save-page", label: "Save Page..."},
        %{kind: "item", value: "create-shortcut", label: "Create Shortcut..."},
        %{kind: "item", value: "name-window", label: "Name Window..."},
        %{kind: "separator"},
        %{kind: "item", value: "developer-tools", label: "Developer Tools"},
        %{kind: "separator"},
        %{kind: "item", value: "delete", label: "Delete", variant: "destructive"}
      ])

    ~H"""
    <.context_menu
      id="context-menu-demo"
      class="w-48"
      trigger_class={context_menu_target_class()}
    >
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="back" shortcut="⌘[">Back</:entry>
      <:entry kind="item" value="forward" shortcut="⌘]" disabled>Forward</:entry>
      <:entry kind="item" value="reload" shortcut="⌘R">Reload</:entry>
      <:entry
        kind="submenu"
        value="more-tools"
        grouped
        items={@more_tools}
        content_attrs={%{class: "w-44"}}
      >
        More Tools
      </:entry>
      <:entry kind="separator" />
      <:entry kind="checkbox" value="show-bookmarks" checked>Show Bookmarks</:entry>
      <:entry kind="checkbox" value="show-full-urls">Show Full URLs</:entry>
      <:entry kind="separator" />
      <:entry
        kind="radio-group"
        group="people"
        label="People"
        value="pedro"
        items={[
          %{value: "pedro", label: "Pedro Duarte"},
          %{value: "colm", label: "Colm Tuite"}
        ]}
      />
    </.context_menu>
    """
  end

  defp context_menu_basic(assigns) do
    ~H"""
    <.context_menu id="context-menu-basic" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="back">Back</:entry>
      <:entry kind="item" value="forward" disabled>Forward</:entry>
      <:entry kind="item" value="reload">Reload</:entry>
    </.context_menu>
    """
  end

  defp context_menu_submenu(assigns) do
    assigns =
      assign(assigns, :more_tools, [
        %{kind: "item", value: "save-page", label: "Save Page..."},
        %{kind: "item", value: "create-shortcut", label: "Create Shortcut..."},
        %{kind: "item", value: "name-window", label: "Name Window..."},
        %{kind: "separator"},
        %{kind: "item", value: "developer-tools", label: "Developer Tools"},
        %{kind: "separator"},
        %{kind: "item", value: "delete", label: "Delete", variant: "destructive"}
      ])

    ~H"""
    <.context_menu
      id="context-menu-submenu"
      grouped={false}
      trigger_class={context_menu_target_class()}
    >
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="copy" section="edit" shortcut="⌘C">Copy</:entry>
      <:entry kind="item" value="cut" section="edit" shortcut="⌘X">Cut</:entry>
      <:entry kind="submenu" value="more-tools" grouped items={@more_tools}>More Tools</:entry>
    </.context_menu>
    """
  end

  defp context_menu_shortcuts(assigns) do
    ~H"""
    <.context_menu id="context-menu-shortcuts" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="back" shortcut="⌘[">Back</:entry>
      <:entry kind="item" value="forward" shortcut="⌘]" disabled>Forward</:entry>
      <:entry kind="item" value="reload" shortcut="⌘R">Reload</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="save" shortcut="⌘S">Save</:entry>
      <:entry kind="item" value="save-as" shortcut="⇧⌘S">Save As...</:entry>
    </.context_menu>
    """
  end

  defp context_menu_groups(assigns) do
    ~H"""
    <.context_menu id="context-menu-groups" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="label">File</:entry>
      <:entry kind="item" value="new-file" shortcut="⌘N">New File</:entry>
      <:entry kind="item" value="open-file" shortcut="⌘O">Open File</:entry>
      <:entry kind="item" value="save" shortcut="⌘S">Save</:entry>
      <:entry kind="separator" />
      <:entry kind="label">Edit</:entry>
      <:entry kind="item" value="undo" shortcut="⌘Z">Undo</:entry>
      <:entry kind="item" value="redo" shortcut="⇧⌘Z">Redo</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="cut" shortcut="⌘X">Cut</:entry>
      <:entry kind="item" value="copy" shortcut="⌘C">Copy</:entry>
      <:entry kind="item" value="paste" shortcut="⌘V">Paste</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="delete" shortcut="⌫" variant="destructive">Delete</:entry>
    </.context_menu>
    """
  end

  defp context_menu_icons(assigns) do
    ~H"""
    <.context_menu id="context-menu-icons" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="copy"><LiveShadcn.Icon.icon name="copy" /> Copy</:entry>
      <:entry kind="item" value="cut"><LiveShadcn.Icon.icon name="scissors" /> Cut</:entry>
      <:entry kind="item" value="paste"><LiveShadcn.Icon.icon name="clipboard-paste" /> Paste</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="delete" variant="destructive">
        <LiveShadcn.Icon.icon name="trash" /> Delete
      </:entry>
    </.context_menu>
    """
  end

  defp context_menu_checkboxes(assigns) do
    ~H"""
    <.context_menu id="context-menu-checkboxes" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="checkbox" value="bookmarks" checked>Show Bookmarks Bar</:entry>
      <:entry kind="checkbox" value="urls">Show Full URLs</:entry>
      <:entry kind="checkbox" value="developer-tools" checked>Show Developer Tools</:entry>
    </.context_menu>
    """
  end

  defp context_menu_radio(assigns) do
    ~H"""
    <.context_menu id="context-menu-radio" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="label">People</:entry>
      <:entry
        kind="radio-group"
        group="people"
        value="pedro"
        items={[
          %{value: "pedro", label: "Pedro Duarte"},
          %{value: "colm", label: "Colm Tuite"}
        ]}
      />
      <:entry kind="separator" />
      <:entry kind="label">Theme</:entry>
      <:entry
        kind="radio-group"
        group="theme"
        value="light"
        items={[
          %{value: "light", label: "Light"},
          %{value: "dark", label: "Dark"},
          %{value: "system", label: "System"}
        ]}
      />
    </.context_menu>
    """
  end

  defp context_menu_destructive(assigns) do
    ~H"""
    <.context_menu id="context-menu-destructive" trigger_class={context_menu_target_class()}>
      <:trigger>
        <.context_menu_target fine="Right click here" coarse="Long press here" />
      </:trigger>
      <:entry kind="item" value="edit"><LiveShadcn.Icon.icon name="pencil" /> Edit</:entry>
      <:entry kind="item" value="share"><LiveShadcn.Icon.icon name="share" /> Share</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="delete" variant="destructive">
        <LiveShadcn.Icon.icon name="trash" /> Delete
      </:entry>
    </.context_menu>
    """
  end

  defp context_menu_sides(assigns) do
    assigns = assign(assigns, :context_menu_sides, ~w(top right bottom left))

    ~H"""
    <div class="grid w-full max-w-sm grid-cols-2 gap-4">
      <.context_menu
        :for={side <- @context_menu_sides}
        id={"context-menu-side-#{side}"}
        side={side}
        trigger_class={context_menu_target_class()}
      >
        <:trigger>
          <.context_menu_target
            fine={"Right click (#{side})"}
            coarse={"Long press (#{side})"}
          />
        </:trigger>
        <:entry kind="item" value="back">Back</:entry>
        <:entry kind="item" value="forward">Forward</:entry>
        <:entry kind="item" value="reload">Reload</:entry>
      </.context_menu>
    </div>
    """
  end

  defp context_menu_rtl(assigns) do
    rtl = %{dir: "rtl", "data-lang": "ar"}

    assigns =
      assigns
      |> assign(:rtl, rtl)
      |> assign(:navigation, [
        %{kind: "item", value: "back", label: "رجوع", icon: "arrow-left", shortcut: "⌘["},
        %{
          kind: "item",
          value: "forward",
          label: "تقدم",
          icon: "arrow-right",
          shortcut: "⌘]",
          disabled: true
        },
        %{
          kind: "item",
          value: "reload",
          label: "إعادة تحميل",
          icon: "rotate-cw",
          shortcut: "⌘R"
        }
      ])
      |> assign(:more_tools, [
        %{kind: "item", value: "save-page", label: "حفظ الصفحة..."},
        %{kind: "item", value: "create-shortcut", label: "إنشاء اختصار..."},
        %{kind: "item", value: "name-window", label: "تسمية النافذة..."},
        %{kind: "separator"},
        %{kind: "item", value: "developer-tools", label: "أدوات المطور"},
        %{kind: "separator"},
        %{kind: "item", value: "delete", label: "حذف", variant: "destructive"}
      ])

    ~H"""
    <.context_menu
      id="context-menu-rtl"
      class="w-48"
      trigger_class={context_menu_target_class()}
      content_attrs={@rtl}
    >
      <:trigger>
        <.context_menu_target
          fine="انقر بزر الماوس الأيمن هنا"
          coarse="اضغط مطولاً هنا"
        />
      </:trigger>
      <:entry
        kind="submenu"
        value="navigation"
        grouped
        items={@navigation}
        content_attrs={Map.put(@rtl, :class, "w-44")}
      >
        التنقل
      </:entry>
      <:entry
        kind="submenu"
        value="more-tools"
        grouped
        items={@more_tools}
        content_attrs={Map.put(@rtl, :class, "w-44")}
      >
        المزيد من الأدوات
      </:entry>
      <:entry kind="separator" />
      <:entry kind="checkbox" value="bookmarks" checked>إظهار الإشارات المرجعية</:entry>
      <:entry kind="checkbox" value="urls">إظهار عناوين URL الكاملة</:entry>
      <:entry kind="separator" />
      <:entry
        kind="radio-group"
        group="people"
        label="الأشخاص"
        value="pedro"
        items={[
          %{value: "pedro", label: "Pedro Duarte"},
          %{value: "colm", label: "Colm Tuite"}
        ]}
      />
    </.context_menu>
    """
  end

  defp navigation_menu_default(assigns) do
    assigns = assign(assigns, :navigation_components, @navigation_components)

    ~H"""
    <.navigation_menu id="navigation-menu-demo">
      <:item id="navigation-menu-demo-start" trigger="Getting started">
        <ul class="w-96">
          <li>
            <.navigation_menu_link href="/docs">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">Introduction</div>
                <div class="line-clamp-2 text-muted-foreground">
                  Re-usable components built with Tailwind CSS.
                </div>
              </div>
            </.navigation_menu_link>
          </li>
          <li>
            <.navigation_menu_link href="/docs/installation">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">Installation</div>
                <div class="line-clamp-2 text-muted-foreground">
                  How to install dependencies and structure your app.
                </div>
              </div>
            </.navigation_menu_link>
          </li>
          <li>
            <.navigation_menu_link href="/docs/primitives/typography">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">Typography</div>
                <div class="line-clamp-2 text-muted-foreground">
                  Styles for headings, paragraphs, lists...etc
                </div>
              </div>
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:item
        id="navigation-menu-demo-components"
        trigger="Components"
        class="hidden md:flex"
      >
        <ul class="grid w-[400px] gap-2 md:w-[500px] md:grid-cols-2 lg:w-[600px]">
          <li :for={component <- @navigation_components}>
            <.navigation_menu_link href={component.href}>
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">{component.title}</div>
                <div class="line-clamp-2 text-muted-foreground">{component.description}</div>
              </div>
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:item id="navigation-menu-demo-icon" trigger="With Icon">
        <ul class="grid w-[200px]">
          <li>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-alert" />{"Backlog"}
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-dashed" />{"To Do"}
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-check" />{"Done"}
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:link href="/docs">Docs</:link>
    </.navigation_menu>
    """
  end

  defp navigation_menu_rtl(assigns) do
    assigns = assign(assigns, :navigation_components_rtl, @navigation_components_rtl)

    ~H"""
    <.navigation_menu id="navigation-menu-rtl" dir="rtl" align="end">
      <:item
        id="navigation-menu-rtl-start"
        trigger="البدء"
        content_attrs={%{dir: "rtl", "data-lang": "ar"}}
      >
        <ul class="w-96">
          <li>
            <.navigation_menu_link href="/docs">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">مقدمة</div>
                <div class="line-clamp-2 text-muted-foreground">
                  مكونات قابلة لإعادة الاستخدام مبنية باستخدام Tailwind CSS.
                </div>
              </div>
            </.navigation_menu_link>
          </li>
          <li>
            <.navigation_menu_link href="/docs/installation">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">التثبيت</div>
                <div class="line-clamp-2 text-muted-foreground">
                  كيفية تثبيت التبعيات وتنظيم تطبيقك.
                </div>
              </div>
            </.navigation_menu_link>
          </li>
          <li>
            <.navigation_menu_link href="/docs/primitives/typography">
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">الطباعة</div>
                <div class="line-clamp-2 text-muted-foreground">
                  أنماط للعناوين والفقرات والقوائم...إلخ
                </div>
              </div>
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:item
        id="navigation-menu-rtl-components"
        trigger="المكونات"
        class="hidden md:flex"
        content_attrs={%{dir: "rtl", "data-lang": "ar"}}
      >
        <ul class="grid w-[400px] gap-2 md:w-[500px] md:grid-cols-2 lg:w-[600px]">
          <li :for={component <- @navigation_components_rtl}>
            <.navigation_menu_link href={component.href}>
              <div class="flex flex-col gap-1 text-sm">
                <div class="leading-none font-medium">{component.title}</div>
                <div class="line-clamp-2 text-muted-foreground">{component.description}</div>
              </div>
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:item
        id="navigation-menu-rtl-icon"
        trigger="مع أيقونة"
        content_attrs={%{dir: "rtl", "data-lang": "ar"}}
      >
        <ul class="grid w-[200px]">
          <li>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-alert" />{"قائمة الانتظار"}
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-dashed" />{"المهام"}
            </.navigation_menu_link>
            <.navigation_menu_link href="#" class="flex-row items-center gap-2">
              <LiveShadcn.Icon.icon name="circle-check" />{"منجز"}
            </.navigation_menu_link>
          </li>
        </ul>
      </:item>
      <:link href="/docs" attrs={%{"data-lang": "ar"}}>الوثائق</:link>
    </.navigation_menu>
    """
  end

  defp dialog_default(assigns) do
    ~H"""
    <form>
      <.dialog id="dialog-default" trigger_variant="outline" class="sm:max-w-sm">
        <:trigger>Open Dialog</:trigger>
        <:title>Edit profile</:title>
        <:description>
          Make changes to your profile here. Click save when you're done.
        </:description>
        <.field_group>
          <.field>
            <.label for="name-1">Name</.label>
            <.input id="name-1" name="name" value="Pedro Duarte" />
          </.field>
          <.field>
            <.label for="username-1">Username</.label>
            <.input id="username-1" name="username" value="@peduarte" />
          </.field>
        </.field_group>
        <:footer>
          <.button
            data-slot="dialog-close"
            variant="outline"
            phx-click={LiveBase.Dialog.close("dialog-default")}
          >
            Cancel
          </.button>
          <.button type="submit">Save changes</.button>
        </:footer>
      </.dialog>
    </form>
    """
  end

  defp dialog_close_button(assigns) do
    ~H"""
    <.dialog
      id="dialog-close-button"
      trigger_variant="outline"
      class="sm:max-w-md"
      footer_class="sm:justify-start"
    >
      <:trigger>Share</:trigger>
      <:title>Share link</:title>
      <:description>Anyone who has this link will be able to view this.</:description>
      <div class="flex items-center gap-2">
        <div class="grid flex-1 gap-2">
          <.label for="link" class="sr-only">Link</.label>
          <.input
            id="link"
            value="https://ui.shadcn.com/docs/installation"
            readonly
          />
        </div>
      </div>
      <:footer>
        <.button
          data-slot="dialog-close"
          type="button"
          phx-click={LiveBase.Dialog.close("dialog-close-button")}
        >
          Close
        </.button>
      </:footer>
    </.dialog>
    """
  end

  defp dialog_no_close_button(assigns) do
    ~H"""
    <.dialog id="dialog-no-close-button" trigger_variant="outline" show_close_button={false}>
      <:trigger>No Close Button</:trigger>
      <:title>No Close Button</:title>
      <:description>
        This dialog doesn't have a close button in the top-right corner.
      </:description>
    </.dialog>
    """
  end

  defp dialog_sticky_footer(assigns) do
    ~H"""
    <.dialog id="dialog-sticky-footer" trigger_variant="outline">
      <:trigger>Sticky Footer</:trigger>
      <:title>Sticky Footer</:title>
      <:description>
        This dialog has a sticky footer that stays visible while the content scrolls.
      </:description>
      <div class="-mx-4 no-scrollbar max-h-[50vh] overflow-y-auto px-4">
        <p :for={_index <- 1..10} class="mb-4 leading-normal">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        </p>
      </div>
      <:footer>
        <.button
          data-slot="dialog-close"
          variant="outline"
          phx-click={LiveBase.Dialog.close("dialog-sticky-footer")}
        >
          Close
        </.button>
      </:footer>
    </.dialog>
    """
  end

  defp dialog_scrollable_content(assigns) do
    ~H"""
    <.dialog id="dialog-scrollable-content" trigger_variant="outline">
      <:trigger>Scrollable Content</:trigger>
      <:title>Scrollable Content</:title>
      <:description>This is a dialog with scrollable content.</:description>
      <div class="-mx-4 no-scrollbar max-h-[50vh] overflow-y-auto px-4">
        <p :for={_index <- 1..10} class="mb-4 leading-normal">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        </p>
      </div>
    </.dialog>
    """
  end

  defp dialog_rtl(assigns) do
    ~H"""
    <form>
      <.dialog
        id="dialog-rtl"
        trigger_variant="outline"
        class="sm:max-w-sm"
        dir="rtl"
        data-lang="ar"
      >
        <:trigger>فتح الحوار</:trigger>
        <:title>تعديل الملف الشخصي</:title>
        <:description>
          قم بإجراء تغييرات على ملفك الشخصي هنا. انقر فوق حفظ عند الانتهاء.
        </:description>
        <.field_group>
          <.field>
            <.label for="name-1">الاسم</.label>
            <.input id="name-1" name="name" value="Pedro Duarte" />
          </.field>
          <.field>
            <.label for="username-1">اسم المستخدم</.label>
            <.input id="username-1" name="username" value="@peduarte" />
          </.field>
        </.field_group>
        <:footer>
          <.button
            data-slot="dialog-close"
            variant="outline"
            phx-click={LiveBase.Dialog.close("dialog-rtl")}
          >
            إلغاء
          </.button>
          <.button type="submit">حفظ التغييرات</.button>
        </:footer>
      </.dialog>
    </form>
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

  defp dropdown_menu_basic(assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-basic" trigger_variant="outline">
      <:trigger>Open</:trigger>
      <:entry kind="label" section="account">My Account</:entry>
      <:entry kind="item" value="profile" section="account">Profile</:entry>
      <:entry kind="item" value="billing" section="account">Billing</:entry>
      <:entry kind="item" value="settings" section="account">Settings</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="github">GitHub</:entry>
      <:entry kind="item" value="support">Support</:entry>
      <:entry kind="item" value="api" disabled>API</:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_submenu(assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-submenu" trigger_variant="outline" grouped>
      <:trigger>Open</:trigger>
      <:entry kind="item" value="team">Team</:entry>
      <:entry
        kind="submenu"
        value="invite-users"
        items={[
          %{value: "email", label: "Email"},
          %{value: "message", label: "Message"},
          %{
            kind: "submenu",
            value: "more-options",
            label: "More options",
            items: [
              %{value: "calendly", label: "Calendly"},
              %{value: "slack", label: "Slack"},
              %{kind: "separator"},
              %{value: "webhook", label: "Webhook"}
            ]
          },
          %{kind: "separator"},
          %{value: "advanced", label: "Advanced..."}
        ]}
      >
        Invite users
      </:entry>
      <:entry kind="item" value="new-team" shortcut="⌘+T">New Team</:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_shortcuts(assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-shortcuts" trigger_variant="outline">
      <:trigger>Open</:trigger>
      <:entry kind="label" section="account">My Account</:entry>
      <:entry kind="item" value="profile" shortcut="⇧⌘P" section="account">Profile</:entry>
      <:entry kind="item" value="billing" shortcut="⌘B" section="account">Billing</:entry>
      <:entry kind="item" value="settings" shortcut="⌘S" section="account">Settings</:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" shortcut="⇧⌘Q">Log out</:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_icons(assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-icons" trigger_variant="outline">
      <:trigger>Open</:trigger>
      <:entry kind="item" value="profile">
        <LiveShadcn.Icon.icon name="user" /> Profile
      </:entry>
      <:entry kind="item" value="billing">
        <LiveShadcn.Icon.icon name="credit-card" /> Billing
      </:entry>
      <:entry kind="item" value="settings">
        <LiveShadcn.Icon.icon name="settings" /> Settings
      </:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" variant="destructive">
        <LiveShadcn.Icon.icon name="log-out" /> Log out
      </:entry>
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

  defp dropdown_menu_checkboxes_icons(assigns) do
    ~H"""
    <.dropdown_menu id="notification-preferences" trigger_variant="outline" class="w-48" grouped>
      <:trigger>Notifications</:trigger>
      <:entry kind="label">Notification Preferences</:entry>
      <:entry kind="checkbox" value="email" checked>
        <LiveShadcn.Icon.icon name="mail" /> Email notifications
      </:entry>
      <:entry kind="checkbox" value="sms">
        <LiveShadcn.Icon.icon name="message-square" /> SMS notifications
      </:entry>
      <:entry kind="checkbox" value="push" checked>
        <LiveShadcn.Icon.icon name="bell" /> Push notifications
      </:entry>
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

  defp dropdown_menu_radio_icons(assigns) do
    ~H"""
    <.dropdown_menu
      id="payment-method"
      trigger_variant="outline"
      class="min-w-56"
      grouped
    >
      <:trigger>Payment Method</:trigger>
      <:entry kind="label">Select Payment Method</:entry>
      <:entry
        kind="radio-group"
        group="method"
        value="card"
        items={[
          %{value: "card", label: "Credit Card", icon: "credit-card"},
          %{value: "paypal", label: "PayPal", icon: "wallet"},
          %{value: "bank", label: "Bank Transfer", icon: "building-2"}
        ]}
      />
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_destructive(assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-destructive" trigger_variant="outline" grouped>
      <:trigger>Actions</:trigger>
      <:entry kind="item" value="edit">
        <LiveShadcn.Icon.icon name="pencil" /> Edit
      </:entry>
      <:entry kind="item" value="share">
        <LiveShadcn.Icon.icon name="share" /> Share
      </:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="delete" variant="destructive">
        <LiveShadcn.Icon.icon name="trash" /> Delete
      </:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_avatar(assigns) do
    ~H"""
    <.dropdown_menu
      id="dropdown-avatar"
      trigger_variant="ghost"
      trigger_size="icon"
      trigger_class="rounded-full"
      align="end"
    >
      <:trigger>
        <.avatar>
          <.avatar_image src="https://github.com/shadcn.png" alt="shadcn" />
          <.avatar_fallback>LR</.avatar_fallback>
        </.avatar>
      </:trigger>
      <:entry kind="item" value="account" section="account">
        <LiveShadcn.Icon.icon name="badge-check" /> Account
      </:entry>
      <:entry kind="item" value="billing" section="account">
        <LiveShadcn.Icon.icon name="credit-card" /> Billing
      </:entry>
      <:entry kind="item" value="notifications" section="account">
        <LiveShadcn.Icon.icon name="bell" /> Notifications
      </:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="sign-out">
        <LiveShadcn.Icon.icon name="log-out" /> Sign Out
      </:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_complex(assigns) do
    ~H"""
    <.dropdown_menu id="complex-actions" trigger_variant="outline" class="w-44">
      <:trigger>Complex Menu</:trigger>
      <:entry kind="label" section="file">File</:entry>
      <:entry kind="item" value="new-file" shortcut="⌘N" section="file">
        <LiveShadcn.Icon.icon name="file" /> New File
      </:entry>
      <:entry kind="item" value="new-folder" shortcut="⇧⌘N" section="file">
        <LiveShadcn.Icon.icon name="folder" /> New Folder
      </:entry>
      <:entry
        kind="submenu"
        value="open-recent"
        section="file"
        grouped
        items={[
          %{kind: "label", label: "Recent Projects"},
          %{value: "project-alpha", label: "Project Alpha", icon: "file-code"},
          %{value: "project-beta", label: "Project Beta", icon: "file-code"},
          %{
            kind: "submenu",
            value: "more-projects",
            label: "More Projects",
            icon: "more-horizontal",
            items: [
              %{value: "project-gamma", label: "Project Gamma", icon: "file-code"},
              %{value: "project-delta", label: "Project Delta", icon: "file-code"}
            ]
          },
          %{kind: "separator"},
          %{value: "browse", label: "Browse...", icon: "folder-search"}
        ]}
      >
        <LiveShadcn.Icon.icon name="folder-open" /> Open Recent
      </:entry>
      <:entry kind="separator" section="file" />
      <:entry kind="item" value="save" shortcut="⌘S" section="file">
        <LiveShadcn.Icon.icon name="save" /> Save
      </:entry>
      <:entry kind="item" value="export" shortcut="⇧⌘E" section="file">
        <LiveShadcn.Icon.icon name="download" /> Export
      </:entry>
      <:entry kind="separator" />
      <:entry kind="label" section="view">View</:entry>
      <:entry kind="checkbox" value="show-sidebar" checked section="view">
        <LiveShadcn.Icon.icon name="eye" /> Show Sidebar
      </:entry>
      <:entry kind="checkbox" value="show-status-bar" section="view">
        <LiveShadcn.Icon.icon name="layout" /> Show Status Bar
      </:entry>
      <:entry
        kind="submenu"
        value="theme"
        section="view"
        grouped
        items={[
          %{kind: "label", label: "Appearance"},
          %{
            kind: "radio-group",
            group: "theme",
            value: "light",
            items: [
              %{value: "light", label: "Light", icon: "sun"},
              %{value: "dark", label: "Dark", icon: "moon"},
              %{value: "system", label: "System", icon: "monitor"}
            ]
          }
        ]}
      >
        <LiveShadcn.Icon.icon name="palette" /> Theme
      </:entry>
      <:entry kind="separator" />
      <:entry kind="label" section="account">Account</:entry>
      <:entry kind="item" value="profile" shortcut="⇧⌘P" section="account">
        <LiveShadcn.Icon.icon name="user" /> Profile
      </:entry>
      <:entry kind="item" value="billing" section="account">
        <LiveShadcn.Icon.icon name="credit-card" /> Billing
      </:entry>
      <:entry
        kind="submenu"
        value="settings"
        section="account"
        grouped
        items={[
          %{kind: "label", label: "Preferences"},
          %{value: "keyboard-shortcuts", label: "Keyboard Shortcuts", icon: "keyboard"},
          %{value: "language", label: "Language", icon: "languages"},
          %{
            kind: "submenu",
            value: "notifications",
            label: "Notifications",
            icon: "bell",
            grouped: true,
            items: [
              %{kind: "label", label: "Notification Types"},
              %{
                kind: "checkbox",
                value: "push-notifications",
                label: "Push Notifications",
                icon: "bell",
                checked: true
              },
              %{
                kind: "checkbox",
                value: "email-notifications",
                label: "Email Notifications",
                icon: "mail",
                checked: true
              }
            ]
          },
          %{kind: "separator"},
          %{value: "privacy-security", label: "Privacy & Security", icon: "shield"}
        ]}
      >
        <LiveShadcn.Icon.icon name="settings" /> Settings
      </:entry>
      <:entry kind="separator" />
      <:entry kind="item" value="help-support" section="help">
        <LiveShadcn.Icon.icon name="circle-help" /> Help &amp; Support
      </:entry>
      <:entry kind="item" value="documentation" section="help">
        <LiveShadcn.Icon.icon name="file-text" /> Documentation
      </:entry>
      <:entry kind="separator" />
      <:entry
        kind="item"
        value="sign-out"
        shortcut="⇧⌘Q"
        variant="destructive"
        section="sign-out"
      >
        <LiveShadcn.Icon.icon name="log-out" /> Sign Out
      </:entry>
    </.dropdown_menu>
    """
  end

  defp dropdown_menu_rtl(assigns) do
    rtl = %{:"data-lang" => "ar", dir: "rtl"}
    assigns = assign(assigns, :rtl, rtl)

    ~H"""
    <.dropdown_menu
      id="dropdown-rtl"
      trigger_variant="outline"
      class="w-36"
      align="end"
      grouped
      dir="rtl"
      content_attrs={@rtl}
    >
      <:trigger>افتح القائمة</:trigger>
      <:entry
        kind="submenu"
        value="account"
        grouped
        content_attrs={@rtl}
        items={[
          %{value: "profile", label: "الملف الشخصي", icon: "user"},
          %{value: "billing", label: "الفوترة", icon: "credit-card"},
          %{value: "settings", label: "الإعدادات", icon: "settings"}
        ]}
      >
        الحساب
      </:entry>
      <:entry kind="separator" />
      <:entry kind="label">الفريق</:entry>
      <:entry kind="item" value="team">الفريق</:entry>
      <:entry
        kind="submenu"
        value="invite-users"
        content_attrs={@rtl}
        items={[
          %{value: "email", label: "البريد الإلكتروني"},
          %{value: "message", label: "رسالة"},
          %{
            kind: "submenu",
            value: "more",
            label: "المزيد",
            content_attrs: @rtl,
            items: [
              %{value: "calendar", label: "تقويم"},
              %{value: "chat", label: "دردشة"},
              %{kind: "separator"},
              %{value: "webhook", label: "خطاف ويب"}
            ]
          },
          %{kind: "separator"},
          %{value: "advanced", label: "متقدم..."}
        ]}
      >
        دعوة المستخدمين
      </:entry>
      <:entry kind="item" value="new-team" shortcut="⌘+T">فريق جديد</:entry>
      <:entry kind="separator" />
      <:entry kind="label">عرض</:entry>
      <:entry kind="checkbox" value="status-bar" checked>شريط الحالة</:entry>
      <:entry kind="checkbox" value="activity-bar">شريط النشاط</:entry>
      <:entry kind="checkbox" value="panel">اللوحة</:entry>
      <:entry kind="separator" />
      <:entry kind="label">الموضع</:entry>
      <:entry
        kind="radio-group"
        group="position"
        value="bottom"
        items={[
          %{value: "top", label: "أعلى"},
          %{value: "bottom", label: "أسفل"},
          %{value: "right", label: "يمين"},
          %{value: "left", label: "يسار"}
        ]}
      />
      <:entry kind="separator" />
      <:entry kind="item" value="log-out" variant="destructive">تسجيل الخروج</:entry>
    </.dropdown_menu>
    """
  end

  defp empty_default(assigns) do
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_media variant="icon"><.tabler_icon name="folder-code" /></.empty_media>
        <.empty_title>No Projects Yet</.empty_title>
        <.empty_description>
          You haven't created any projects yet. Get started by creating your first project.
        </.empty_description>
      </.empty_header>
      <.empty_content class="flex-row justify-center gap-2">
        <.button>Create Project</.button>
        <.button variant="outline">Import Project</.button>
      </.empty_content>
      <.button_link href="#" variant="link" class="text-muted-foreground" size="sm">
        Learn More <LiveShadcn.Icon.icon name="arrow-up-right" />
      </.button_link>
    </.empty>
    """
  end

  defp empty_outline(assigns) do
    ~H"""
    <.empty class="border border-dashed">
      <.empty_header>
        <.empty_media variant="icon"><.tabler_icon name="cloud" /></.empty_media>
        <.empty_title>Cloud Storage Empty</.empty_title>
        <.empty_description>
          Upload files to your cloud storage to access them anywhere.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.button variant="outline" size="sm">Upload Files</.button>
      </.empty_content>
    </.empty>
    """
  end

  defp empty_background(assigns) do
    ~H"""
    <.empty class="h-full bg-muted/30">
      <.empty_header>
        <.empty_media variant="icon"><.tabler_icon name="bell" /></.empty_media>
        <.empty_title>No Notifications</.empty_title>
        <.empty_description class="max-w-xs text-pretty">
          You're all caught up. New notifications will appear here.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.button variant="outline">
          <LiveShadcn.Icon.icon name="refresh-ccw" data-icon="inline-start" /> Refresh
        </.button>
      </.empty_content>
    </.empty>
    """
  end

  defp empty_avatar(assigns) do
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_media>
          <.avatar class="size-12">
            <.avatar_image src="https://github.com/shadcn.png" alt="" class="grayscale" />
            <.avatar_fallback>LR</.avatar_fallback>
          </.avatar>
        </.empty_media>
        <.empty_title>User Offline</.empty_title>
        <.empty_description>
          This user is currently offline. You can leave a message to notify them or try again later.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.button size="sm">Leave Message</.button>
      </.empty_content>
    </.empty>
    """
  end

  defp empty_avatar_group(assigns) do
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_media>
          <div class="flex -space-x-2 *:data-[slot=avatar]:size-12 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale">
            <.avatar>
              <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
              <.avatar_fallback>CN</.avatar_fallback>
            </.avatar>
            <.avatar>
              <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
              <.avatar_fallback>LR</.avatar_fallback>
            </.avatar>
            <.avatar>
              <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
              <.avatar_fallback>ER</.avatar_fallback>
            </.avatar>
          </div>
        </.empty_media>
        <.empty_title>No Team Members</.empty_title>
        <.empty_description>
          Invite your team to collaborate on this project.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.button size="sm">
          <LiveShadcn.Icon.icon name="plus" /> Invite Members
        </.button>
      </.empty_content>
    </.empty>
    """
  end

  defp empty_input_group(assigns) do
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_title>404 - Not Found</.empty_title>
        <.empty_description>
          The page you're looking for doesn't exist. Try searching for what you need below.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.input_group class="sm:w-3/4">
          <.input_group_input placeholder="Try searching for pages..." />
          <.input_group_addon><LiveShadcn.Icon.icon name="search" /></.input_group_addon>
          <.input_group_addon align="inline-end">
            <.kbd>/</.kbd>
          </.input_group_addon>
        </.input_group>
        <.empty_description>
          Need help? <a href="#">Contact support</a>
        </.empty_description>
      </.empty_content>
    </.empty>
    """
  end

  defp empty_rtl(assigns) do
    ~H"""
    <.empty dir="rtl">
      <.empty_header>
        <.empty_media variant="icon"><.tabler_icon name="folder-code" /></.empty_media>
        <.empty_title>لا توجد مشاريع بعد</.empty_title>
        <.empty_description>
          لم تقم بإنشاء أي مشاريع بعد. ابدأ بإنشاء مشروعك الأول.
        </.empty_description>
      </.empty_header>
      <.empty_content class="flex-row justify-center gap-2">
        <.button>إنشاء مشروع</.button>
        <.button variant="outline">استيراد مشروع</.button>
      </.empty_content>
      <.button_link href="#" variant="link" class="text-muted-foreground" size="sm">
        تعرف على المزيد
        <LiveShadcn.Icon.icon
          name="arrow-up-right"
          class="rtl:rotate-270"
          data-icon="inline-end"
        />
      </.button_link>
    </.empty>
    """
  end

  attr(:href, :string, required: true)
  attr(:variant, :string, required: true)
  attr(:size, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  defp button_link(assigns) do
    ~H"""
    <a
      href={@href}
      role="button"
      data-slot="button"
      class={
        LiveShadcn.Cn.merge([
          LiveShadcn.UI.Button.part_class("button"),
          LiveShadcn.UI.Button.variant_class("buttonVariants", "variant", @variant),
          LiveShadcn.UI.Button.variant_class("buttonVariants", "size", @size),
          @class
        ])
      }
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr(:name, :string,
    required: true,
    values: [
      "bell",
      "brand-javascript",
      "check",
      "cloud",
      "copy",
      "corner-down-left",
      "folder-code",
      "git-branch",
      "git-fork",
      "info-circle",
      "plus",
      "refresh",
      "star"
    ]
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ["data-favorite", "data-icon", "data-lb-state", "hidden", "id"])

  defp tabler_icon(assigns) do
    assigns = assign(assigns, :paths, tabler_icon_paths(assigns.name))

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={["tabler-icon tabler-icon-#{@name}", @class]}
      {@rest}
    >
      <path :for={path <- @paths} d={path} />
    </svg>
    """
  end

  defp tabler_icon_paths("folder-code") do
    [
      "M11 19h-6a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v4",
      "M20 21l2 -2l-2 -2",
      "M17 17l-2 2l2 2"
    ]
  end

  defp tabler_icon_paths("brand-javascript") do
    [
      "M20 4l-2 14.5l-6 2l-6 -2l-2 -14.5z",
      "M7.5 8h3v8l-2 -1",
      "M16.5 8h-2.5a.5 .5 0 0 0 -.5 .5v3a.5 .5 0 0 0 .5 .5h1.423a.5 .5 0 0 1 .495 .57l-.418 2.93l-2 .5"
    ]
  end

  defp tabler_icon_paths("copy") do
    [
      "M7 7m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z",
      "M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1"
    ]
  end

  defp tabler_icon_paths("check"), do: ["M5 12l5 5l10 -10"]

  defp tabler_icon_paths("plus"), do: ["M12 5l0 14", "M5 12l14 0"]

  defp tabler_icon_paths("corner-down-left") do
    ["M18 6v6a3 3 0 0 1 -3 3h-10l4 -4m0 8l-4 -4"]
  end

  defp tabler_icon_paths("info-circle") do
    ["M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0", "M12 9h.01", "M11 12h1v4h1"]
  end

  defp tabler_icon_paths("cloud") do
    [
      "M6.657 18c-2.572 0 -4.657 -2.007 -4.657 -4.483c0 -2.475 2.085 -4.482 4.657 -4.482c.393 -1.762 1.794 -3.2 3.675 -3.773c1.88 -.572 3.956 -.193 5.444 1c1.488 1.19 2.162 3.007 1.77 4.769h.99c1.913 0 3.464 1.56 3.464 3.486c0 1.927 -1.551 3.487 -3.465 3.487h-11.878"
    ]
  end

  defp tabler_icon_paths("refresh") do
    [
      "M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4",
      "M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"
    ]
  end

  defp tabler_icon_paths("star"),
    do: [
      "M12 17.75l-6.172 3.245l1.179 -6.873l-5 -4.867l6.9 -1l3.086 -6.253l3.086 6.253l6.9 1l-5 4.867l1.179 6.873z"
    ]

  defp tabler_icon_paths("bell") do
    [
      "M10 5a2 2 0 1 1 4 0a7 7 0 0 1 4 6v3a4 4 0 0 0 2 3h-16a4 4 0 0 0 2 -3v-3a7 7 0 0 1 4 -6",
      "M9 17v1a3 3 0 0 0 6 0v-1"
    ]
  end

  defp tabler_icon_paths("git-branch") do
    [
      "M7 18m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M7 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M17 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M7 8l0 8",
      "M9 18h6a2 2 0 0 0 2 -2v-5",
      "M14 14l3 -3l3 3"
    ]
  end

  defp tabler_icon_paths("git-fork") do
    [
      "M12 18m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M7 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M17 6m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M7 8v2a2 2 0 0 0 2 2h6a2 2 0 0 0 2 -2v-2",
      "M12 12l0 4"
    ]
  end

  defp kbd_default(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <.kbd_group>
        <.kbd>⌘</.kbd>
        <.kbd>⇧</.kbd>
        <.kbd>⌥</.kbd>
        <.kbd>⌃</.kbd>
      </.kbd_group>
      <.kbd_group>
        <.kbd>Ctrl</.kbd>
        <span>+</span>
        <.kbd>B</.kbd>
      </.kbd_group>
    </div>
    """
  end

  defp kbd_group_example(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <p class="text-sm text-muted-foreground">
        Use
        <.kbd_group>
          <.kbd>Ctrl + B</.kbd><.kbd>Ctrl + K</.kbd>
        </.kbd_group>
        to open the command palette
      </p>
    </div>
    """
  end

  defp kbd_button(assigns) do
    ~H"""
    <.button variant="outline">
      Accept
      <.kbd data-icon="inline-end" class="translate-x-0.5">⏎</.kbd>
    </.button>
    """
  end

  defp kbd_tooltip(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-4">
      <.button_group>
        <.tooltip id="kbd-save">
          <:trigger>Save</:trigger>
          Save Changes
          <.kbd>S</.kbd>
        </.tooltip>
        <.tooltip id="kbd-print">
          <:trigger>Print</:trigger>
          Print Document
          <.kbd_group>
            <.kbd>Ctrl</.kbd><.kbd>P</.kbd>
          </.kbd_group>
        </.tooltip>
      </.button_group>
    </div>
    """
  end

  defp kbd_input_group(assigns) do
    ~H"""
    <div class="flex w-full max-w-xs flex-col gap-6">
      <.input_group>
        <.input_group_input placeholder="Search..." />
        <.input_group_addon><LiveShadcn.Icon.icon name="search" /></.input_group_addon>
        <.input_group_addon align="inline-end">
          <.kbd>⌘</.kbd><.kbd>K</.kbd>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp kbd_rtl(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4" dir="rtl">
      <.kbd_group>
        <.kbd>⌘</.kbd>
        <.kbd>⇧</.kbd>
        <.kbd>⌥</.kbd>
        <.kbd>⌃</.kbd>
      </.kbd_group>
      <.kbd_group>
        <.kbd>Ctrl</.kbd>
        <span>+</span>
        <.kbd>B</.kbd>
      </.kbd_group>
    </div>
    """
  end

  defp popover_default(assigns) do
    ~H"""
    <.popover id="popover-default" class="w-80">
      <:trigger>Open popover</:trigger>
      <div class="grid gap-4">
        <div class="space-y-2">
          <h4 class="leading-none font-medium">Dimensions</h4>
          <p class="text-sm text-muted-foreground">Set the dimensions for the layer.</p>
        </div>
        <div class="grid gap-2">
          <div class="grid grid-cols-3 items-center gap-4">
            <.label for="width">Width</.label>
            <.input id="width" value="100%" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <.label for="maxWidth">Max. width</.label>
            <.input id="maxWidth" value="300px" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <.label for="height">Height</.label>
            <.input id="height" value="25px" class="col-span-2 h-8" />
          </div>
          <div class="grid grid-cols-3 items-center gap-4">
            <.label for="maxHeight">Max. height</.label>
            <.input id="maxHeight" value="none" class="col-span-2 h-8" />
          </div>
        </div>
      </div>
    </.popover>
    """
  end

  defp popover_basic(assigns) do
    ~H"""
    <.popover id="popover-basic" align="start" trigger_class="w-fit">
      <:trigger>Open Popover</:trigger>
      <:title>Dimensions</:title>
      <:description>Set the dimensions for the layer.</:description>
    </.popover>
    """
  end

  defp popover_alignments(assigns) do
    ~H"""
    <div class="flex gap-6">
      <.popover id="popover-alignment-start" align="start" class="w-40" trigger_size="sm">
        <:trigger>Start</:trigger>
        Aligned to start
      </.popover>
      <.popover id="popover-alignment-center" align="center" class="w-40" trigger_size="sm">
        <:trigger>Center</:trigger>
        Aligned to center
      </.popover>
      <.popover id="popover-alignment-end" align="end" class="w-40" trigger_size="sm">
        <:trigger>End</:trigger>
        Aligned to end
      </.popover>
    </div>
    """
  end

  defp popover_form(assigns) do
    ~H"""
    <.popover id="popover-form" align="start" class="w-64">
      <:trigger>Open Popover</:trigger>
      <:title>Dimensions</:title>
      <:description>Set the dimensions for the layer.</:description>
      <.field_group class="gap-4">
        <.field orientation="horizontal">
          <.field_label for="popover-form-width" class="w-1/2">Width</.field_label>
          <.input id="popover-form-width" value="100%" />
        </.field>
        <.field orientation="horizontal">
          <.field_label for="popover-form-height" class="w-1/2">Height</.field_label>
          <.input id="popover-form-height" value="25px" />
        </.field>
      </.field_group>
    </.popover>
    """
  end

  defp popover_rtl(assigns) do
    ~H"""
    <div class="grid gap-4">
      <div class="flex flex-wrap justify-center gap-2">
        <.popover
          :for={
            {side, label} <- [
              {"left", "يسار"},
              {"top", "أعلى"},
              {"bottom", "أسفل"},
              {"right", "يمين"}
            ]
          }
          id={"popover-rtl-#{side}"}
          side={side}
          dir="rtl"
        >
          <:trigger>{label}</:trigger>
          <:title>الأبعاد</:title>
          <:description>تعيين الأبعاد للطبقة.</:description>
        </.popover>
      </div>
      <div class="flex flex-wrap justify-center gap-2">
        <.popover
          :for={{side, label} <- [{"inline-start", "بداية السطر"}, {"inline-end", "نهاية السطر"}]}
          id={"popover-rtl-#{side}"}
          side={side}
          dir="rtl"
        >
          <:trigger>{label}</:trigger>
          <:title>الأبعاد</:title>
          <:description>تعيين الأبعاد للطبقة.</:description>
        </.popover>
      </div>
    </div>
    """
  end

  defp tooltip_default(assigns) do
    ~H"""
    <.tooltip id="tooltip-default">
      <:trigger>Hover</:trigger>
      <p>Add to library</p>
    </.tooltip>
    """
  end

  defp tooltip_sides(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <.tooltip
        :for={side <- ~w(left top bottom right)}
        id={"tooltip-side-#{side}"}
        side={side}
        trigger_class="w-fit capitalize"
      >
        <:trigger>{side}</:trigger>
        <p>Add to library</p>
      </.tooltip>
    </div>
    """
  end

  defp tooltip_keyboard(assigns) do
    ~H"""
    <.tooltip id="tooltip-keyboard" trigger_size="icon-sm">
      <:trigger><LiveShadcn.Icon.icon name="save" /></:trigger>
      Save Changes
      <.kbd>S</.kbd>
    </.tooltip>
    """
  end

  defp tooltip_disabled(assigns) do
    ~H"""
    <.tooltip id="tooltip-disabled" trigger_as="span" trigger_class="inline-block w-fit">
      <:trigger><.button variant="outline" disabled>Disabled</.button></:trigger>
      <p>This feature is currently unavailable</p>
    </.tooltip>
    """
  end

  defp tooltip_rtl(assigns) do
    ~H"""
    <div class="grid gap-4">
      <div class="flex flex-wrap justify-center gap-2">
        <.tooltip
          :for={
            {side, label} <- [
              {"left", "يسار"},
              {"top", "أعلى"},
              {"bottom", "أسفل"},
              {"right", "يمين"}
            ]
          }
          id={"tooltip-rtl-#{side}"}
          side={side}
          dir="rtl"
        >
          <:trigger>{label}</:trigger>
          إضافة إلى المكتبة
        </.tooltip>
      </div>
      <div class="flex flex-wrap justify-center gap-2">
        <.tooltip
          :for={{side, label} <- [{"inline-start", "بداية السطر"}, {"inline-end", "نهاية السطر"}]}
          id={"tooltip-rtl-#{side}"}
          side={side}
          dir="rtl"
        >
          <:trigger>{label}</:trigger>
          إضافة إلى المكتبة
        </.tooltip>
      </div>
    </div>
    """
  end

  defp progress_default(assigns) do
    ~H"""
    <.progress value={to_string(@progress_demo_value)} class="w-[60%]" />
    """
  end

  defp progress_label_example(assigns) do
    ~H"""
    <.progress value="56" label="Upload progress" class="w-full max-w-sm">
      <.progress_label>Upload progress</.progress_label>
      <.progress_value>56%</.progress_value>
    </.progress>
    """
  end

  defp progress_controlled(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-4">
      <.progress value={to_string(@progress_value)} class="w-full" />
      <.slider
        id="progress-slider"
        name="value"
        value={@progress_value}
        min={0}
        max={100}
        step={1}
        on_change="progress_value"
      />
    </div>
    """
  end

  defp progress_rtl(assigns) do
    ~H"""
    <.progress value="56" label="تقدم الرفع" class="w-full max-w-sm" dir="rtl">
      <.progress_label>تقدم الرفع</.progress_label>
      <.progress_value><span class="ms-auto">٥٦%</span></.progress_value>
    </.progress>
    """
  end

  defp radio_group_default(assigns) do
    ~H"""
    <.radio_group id="radio-default" class="w-fit">
      <div class="flex items-center gap-3">
        <.radio_group_item id="r1" group="radio-default" value="default" />
        <.label for="r1">Default</.label>
      </div>
      <div class="flex items-center gap-3">
        <.radio_group_item id="r2" group="radio-default" value="comfortable" checked />
        <.label for="r2">Comfortable</.label>
      </div>
      <div class="flex items-center gap-3">
        <.radio_group_item id="r3" group="radio-default" value="compact" />
        <.label for="r3">Compact</.label>
      </div>
    </.radio_group>
    """
  end

  defp radio_group_description(assigns) do
    ~H"""
    <.radio_group id="radio-description" class="w-fit">
      <.field orientation="horizontal">
        <.radio_group_item id="desc-r1" group="radio-description" value="default" />
        <.field_content>
          <.field_label for="desc-r1">Default</.field_label>
          <.field_description>Standard spacing for most use cases.</.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="desc-r2" group="radio-description" value="comfortable" checked />
        <.field_content>
          <.field_label for="desc-r2">Comfortable</.field_label>
          <.field_description>More space between elements.</.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="desc-r3" group="radio-description" value="compact" />
        <.field_content>
          <.field_label for="desc-r3">Compact</.field_label>
          <.field_description>Minimal spacing for dense layouts.</.field_description>
        </.field_content>
      </.field>
    </.radio_group>
    """
  end

  defp radio_group_choice_card(assigns) do
    ~H"""
    <.radio_group id="radio-choice-card" class="max-w-sm">
      <.field_label for="plus-plan">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Plus</.field_title>
            <.field_description>For individuals and small teams.</.field_description>
          </.field_content>
          <.radio_group_item id="plus-plan" group="radio-choice-card" value="plus" checked />
        </.field>
      </.field_label>
      <.field_label for="pro-plan">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Pro</.field_title>
            <.field_description>For growing businesses.</.field_description>
          </.field_content>
          <.radio_group_item id="pro-plan" group="radio-choice-card" value="pro" />
        </.field>
      </.field_label>
      <.field_label for="enterprise-plan">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Enterprise</.field_title>
            <.field_description>For large teams and enterprises.</.field_description>
          </.field_content>
          <.radio_group_item id="enterprise-plan" group="radio-choice-card" value="enterprise" />
        </.field>
      </.field_label>
    </.radio_group>
    """
  end

  defp radio_group_fieldset(assigns) do
    ~H"""
    <.field_set class="w-full max-w-xs">
      <.field_legend variant="label">Subscription Plan</.field_legend>
      <.field_description>Yearly and lifetime plans offer significant savings.</.field_description>
      <.radio_group id="radio-fieldset">
        <.field orientation="horizontal">
          <.radio_group_item id="plan-monthly" group="radio-fieldset" value="monthly" checked />
          <.field_label for="plan-monthly" class="font-normal">Monthly ($9.99/month)</.field_label>
        </.field>
        <.field orientation="horizontal">
          <.radio_group_item id="plan-yearly" group="radio-fieldset" value="yearly" />
          <.field_label for="plan-yearly" class="font-normal">Yearly ($99.99/year)</.field_label>
        </.field>
        <.field orientation="horizontal">
          <.radio_group_item id="plan-lifetime" group="radio-fieldset" value="lifetime" />
          <.field_label for="plan-lifetime" class="font-normal">Lifetime ($299.99)</.field_label>
        </.field>
      </.radio_group>
    </.field_set>
    """
  end

  defp radio_group_disabled(assigns) do
    ~H"""
    <.radio_group id="radio-disabled" class="w-fit">
      <.field orientation="horizontal" data-disabled="true">
        <.radio_group_item id="disabled-1" group="radio-disabled" value="option1" disabled />
        <.field_label for="disabled-1" class="font-normal">Disabled</.field_label>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="disabled-2" group="radio-disabled" value="option2" checked />
        <.field_label for="disabled-2" class="font-normal">Option 2</.field_label>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="disabled-3" group="radio-disabled" value="option3" />
        <.field_label for="disabled-3" class="font-normal">Option 3</.field_label>
      </.field>
    </.radio_group>
    """
  end

  defp radio_group_invalid(assigns) do
    ~H"""
    <.field_set class="w-full max-w-xs">
      <.field_legend variant="label">Notification Preferences</.field_legend>
      <.field_description>Choose how you want to receive notifications.</.field_description>
      <.radio_group id="radio-invalid">
        <.field orientation="horizontal" data-invalid="true">
          <.radio_group_item
            id="invalid-email"
            group="radio-invalid"
            value="email"
            checked
            aria-invalid="true"
          />
          <.field_label for="invalid-email" class="font-normal">Email only</.field_label>
        </.field>
        <.field orientation="horizontal" data-invalid="true">
          <.radio_group_item id="invalid-sms" group="radio-invalid" value="sms" aria-invalid="true" />
          <.field_label for="invalid-sms" class="font-normal">SMS only</.field_label>
        </.field>
        <.field orientation="horizontal" data-invalid="true">
          <.radio_group_item id="invalid-both" group="radio-invalid" value="both" aria-invalid="true" />
          <.field_label for="invalid-both" class="font-normal">Both Email & SMS</.field_label>
        </.field>
      </.radio_group>
    </.field_set>
    """
  end

  defp radio_group_rtl(assigns) do
    ~H"""
    <.radio_group id="radio-rtl" class="w-fit" dir="rtl">
      <.field orientation="horizontal">
        <.radio_group_item id="r1-rtl" group="radio-rtl" value="default" dir="rtl" />
        <.field_content>
          <.field_label for="r1-rtl" dir="rtl">افتراضي</.field_label>
          <.field_description dir="rtl">تباعد قياسي لمعظم حالات الاستخدام.</.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="r2-rtl" group="radio-rtl" value="comfortable" checked dir="rtl" />
        <.field_content>
          <.field_label for="r2-rtl" dir="rtl">مريح</.field_label>
          <.field_description dir="rtl">مساحة أكبر بين العناصر.</.field_description>
        </.field_content>
      </.field>
      <.field orientation="horizontal">
        <.radio_group_item id="r3-rtl" group="radio-rtl" value="compact" dir="rtl" />
        <.field_content>
          <.field_label for="r3-rtl" dir="rtl">مضغوط</.field_label>
          <.field_description dir="rtl">تباعد أدنى للتخطيطات الكثيفة.</.field_description>
        </.field_content>
      </.field>
    </.radio_group>
    """
  end

  defp select_default(assigns) do
    assigns = assign(assigns, :select_fruits, @select_fruits)

    ~H"""
    <.select id="select-fruit" placeholder="Select a fruit" trigger_class="w-full max-w-48">
      <:group label="Fruits" options={[%{label: "Select a fruit", value: ""} | @select_fruits]} />
    </.select>
    """
  end

  defp select_align_item(assigns) do
    assigns = assign(assigns, :select_fruits, @select_fruits)

    ~H"""
    <.field_group class="w-full max-w-xs">
      <.field orientation="horizontal">
        <.field_content>
          <.field_label for="align-item">Align Item</.field_label>
          <.field_description>Toggle to align the item with the trigger.</.field_description>
        </.field_content>
        <.switch
          id="align-item"
          checked={@select_align_item}
          on_toggle="select_align_item"
        />
      </.field>
      <.field>
        <.select
          id="select-align-fruit"
          value="banana"
          align_item_with_trigger={@select_align_item}
        >
          <:option value="" label="Select a fruit" />
          <:option :for={fruit <- @select_fruits} value={fruit.value} label={fruit.label} />
        </.select>
      </.field>
    </.field_group>
    """
  end

  defp select_groups(assigns) do
    vegetables = [
      %{label: "Carrot", value: "carrot"},
      %{label: "Broccoli", value: "broccoli"},
      %{label: "Spinach", value: "spinach"}
    ]

    assigns = assign(assigns, select_fruits: @select_fruits, vegetables: vegetables)

    ~H"""
    <.select id="select-groups" placeholder="Select a fruit" trigger_class="w-full max-w-48">
      <:group label="Fruits" options={Enum.take(@select_fruits, 3)} />
      <:group label="Vegetables" options={@vegetables} separator />
    </.select>
    """
  end

  defp select_scrollable(assigns) do
    assigns = assign(assigns, :select_timezones, @select_timezones)

    ~H"""
    <.select id="select-timezone" placeholder="Select a timezone" trigger_class="w-full max-w-64">
      <:group :for={{label, options} <- @select_timezones} label={label} options={options} />
    </.select>
    """
  end

  defp select_disabled(assigns) do
    options =
      Enum.map(@select_fruits, fn fruit ->
        if fruit.value == "grapes", do: Map.put(fruit, :disabled, true), else: fruit
      end)

    assigns = assign(assigns, :options, [%{label: "Select a fruit", value: ""} | options])

    ~H"""
    <%!-- Base UI names this trigger through its value. Keep this local fixture named for Axe. --%>
    <.select
      id="select-disabled"
      disabled
      labelledby="select-disabled-value"
      trigger_class="w-full max-w-48"
    >
      <:group options={@options} />
    </.select>
    """
  end

  defp select_invalid(assigns) do
    assigns =
      assign(assigns, :options, [
        %{label: "Select a fruit", value: ""} | Enum.take(@select_fruits, 3)
      ])

    ~H"""
    <.field data-invalid="true" class="w-full max-w-48">
      <.field_label>Fruit</.field_label>
      <.select
        id="select-invalid"
        errors={["Please select a fruit."]}
      >
        <:group options={@options} />
      </.select>
      <.field_error>Please select a fruit.</.field_error>
    </.field>
    """
  end

  defp select_rtl(assigns) do
    fruits = [
      %{label: "تفاح", value: "apple"},
      %{label: "موز", value: "banana"},
      %{label: "توت أزرق", value: "blueberry"},
      %{label: "عنب", value: "grapes"},
      %{label: "أناناس", value: "pineapple"}
    ]

    vegetables = [
      %{label: "جزر", value: "carrot"},
      %{label: "بروكلي", value: "broccoli"},
      %{label: "سبانخ", value: "spinach"}
    ]

    assigns = assign(assigns, fruits: fruits, vegetables: vegetables)

    ~H"""
    <.select
      id="select-rtl"
      placeholder="اختر فاكهة"
      trigger_class="w-32"
      dir="rtl"
      content_lang="ar"
    >
      <:group label="الفواكه" options={@fruits} />
      <:group label="الخضروات" options={@vegetables} separator />
    </.select>
    """
  end

  defp separator_default(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-4 text-sm">
      <div class="flex flex-col gap-1.5">
        <div class="leading-none font-medium">shadcn/ui</div>
        <div class="text-muted-foreground">The Foundation for your Design System</div>
      </div>
      <.separator />
      <div>
        A set of beautifully designed components that you can customize, extend, and build on.
      </div>
    </div>
    """
  end

  defp separator_vertical(assigns) do
    ~H"""
    <div class="flex h-5 items-center gap-4 text-sm">
      <div>Blog</div>
      <.separator orientation="vertical" />
      <div>Docs</div>
      <.separator orientation="vertical" />
      <div>Source</div>
    </div>
    """
  end

  defp separator_menu(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-sm md:gap-4">
      <div class="flex flex-col gap-1">
        <span class="font-medium">Settings</span>
        <span class="text-xs text-muted-foreground">Manage preferences</span>
      </div>
      <.separator orientation="vertical" />
      <div class="flex flex-col gap-1">
        <span class="font-medium">Account</span>
        <span class="text-xs text-muted-foreground">Profile &amp; security</span>
      </div>
      <.separator orientation="vertical" class="hidden md:block" />
      <div class="hidden flex-col gap-1 md:flex">
        <span class="font-medium">Help</span>
        <span class="text-xs text-muted-foreground">Support &amp; docs</span>
      </div>
    </div>
    """
  end

  defp separator_list(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-2 text-sm">
      <dl class="flex items-center justify-between">
        <dt>Item 1</dt>
        <dd class="text-muted-foreground">Value 1</dd>
      </dl>
      <.separator />
      <dl class="flex items-center justify-between">
        <dt>Item 2</dt>
        <dd class="text-muted-foreground">Value 2</dd>
      </dl>
      <.separator />
      <dl class="flex items-center justify-between">
        <dt>Item 3</dt>
        <dd class="text-muted-foreground">Value 3</dd>
      </dl>
    </div>
    """
  end

  defp separator_rtl(assigns) do
    ~H"""
    <div class="flex max-w-sm flex-col gap-4 text-sm" dir="rtl">
      <div class="flex flex-col gap-1.5">
        <div class="leading-none font-medium">shadcn/ui</div>
        <div class="text-muted-foreground">الأساس لنظام التصميم الخاص بك</div>
      </div>
      <.separator />
      <div>مجموعة من المكونات المصممة بشكل جميل يمكنك تخصيصها وتوسيعها والبناء عليها.</div>
    </div>
    """
  end

  defp skeleton_default(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <.skeleton class="h-12 w-12 rounded-full" />
      <div class="space-y-2">
        <.skeleton class="h-4 w-[250px]" />
        <.skeleton class="h-4 w-[200px]" />
      </div>
    </div>
    """
  end

  defp skeleton_avatar(assigns) do
    ~H"""
    <div class="flex w-fit items-center gap-4">
      <.skeleton class="size-10 shrink-0 rounded-full" />
      <div class="grid gap-2">
        <.skeleton class="h-4 w-[150px]" />
        <.skeleton class="h-4 w-[100px]" />
      </div>
    </div>
    """
  end

  defp skeleton_card(assigns) do
    ~H"""
    <.card class="w-full max-w-xs">
      <.card_header>
        <.skeleton class="h-4 w-2/3" />
        <.skeleton class="h-4 w-1/2" />
      </.card_header>
      <.card_content>
        <.skeleton class="aspect-video w-full" />
      </.card_content>
    </.card>
    """
  end

  defp skeleton_text(assigns) do
    ~H"""
    <div class="flex w-full max-w-xs flex-col gap-2">
      <.skeleton class="h-4 w-full" />
      <.skeleton class="h-4 w-full" />
      <.skeleton class="h-4 w-3/4" />
    </div>
    """
  end

  defp skeleton_form(assigns) do
    ~H"""
    <div class="flex w-full max-w-xs flex-col gap-7">
      <div class="flex flex-col gap-3">
        <.skeleton class="h-4 w-20" />
        <.skeleton class="h-8 w-full" />
      </div>
      <div class="flex flex-col gap-3">
        <.skeleton class="h-4 w-24" />
        <.skeleton class="h-8 w-full" />
      </div>
      <.skeleton class="h-8 w-24" />
    </div>
    """
  end

  defp skeleton_table(assigns) do
    ~H"""
    <div class="flex w-full max-w-sm flex-col gap-2">
      <div :for={_index <- 0..4} class="flex gap-4">
        <.skeleton class="h-4 flex-1" />
        <.skeleton class="h-4 w-24" />
        <.skeleton class="h-4 w-20" />
      </div>
    </div>
    """
  end

  defp skeleton_rtl(assigns) do
    ~H"""
    <div class="flex items-center gap-4" dir="rtl">
      <.skeleton class="h-12 w-12 rounded-full" />
      <div class="space-y-2">
        <.skeleton class="h-4 w-[250px]" />
        <.skeleton class="h-4 w-[200px]" />
      </div>
    </div>
    """
  end

  defp spinner_default(assigns) do
    ~H"""
    <div class="flex w-full max-w-xs flex-col gap-4 [--radius:1rem]">
      <.item variant="muted">
        <.item_media><.spinner /></.item_media>
        <.item_content>
          <.item_title class="line-clamp-1">Processing payment...</.item_title>
        </.item_content>
        <.item_content class="flex-none justify-end">
          <span class="text-sm tabular-nums">$100.00</span>
        </.item_content>
      </.item>
    </div>
    """
  end

  defp spinner_custom(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <LiveShadcn.Icon.icon
        name="loader"
        role="status"
        aria-label="Loading"
        class="size-4 animate-spin"
      />
    </div>
    """
  end

  defp spinner_size(assigns) do
    ~H"""
    <div class="flex items-center gap-6">
      <.spinner class="size-3" />
      <.spinner class="size-4" />
      <.spinner class="size-6" />
      <.spinner class="size-8" />
    </div>
    """
  end

  defp spinner_button(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <.button disabled size="sm">
        <.spinner data-icon="inline-start" /> Loading...
      </.button>
      <.button variant="outline" disabled size="sm">
        <.spinner data-icon="inline-start" /> Please wait
      </.button>
      <.button variant="secondary" disabled size="sm">
        <.spinner data-icon="inline-start" /> Processing
      </.button>
    </div>
    """
  end

  defp spinner_badge(assigns) do
    ~H"""
    <div class="flex items-center gap-4 [--radius:1.2rem]">
      <.badge><.spinner data-icon="inline-start" /> Syncing</.badge>
      <.badge variant="secondary"><.spinner data-icon="inline-start" /> Updating</.badge>
      <.badge variant="outline"><.spinner data-icon="inline-start" /> Processing</.badge>
    </div>
    """
  end

  defp spinner_input_group(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-4">
      <.input_group>
        <.input_group_input placeholder="Send a message..." disabled />
        <.input_group_addon align="inline-end"><.spinner /></.input_group_addon>
      </.input_group>
      <.input_group>
        <.input_group_textarea placeholder="Send a message..." disabled />
        <.input_group_addon align="block-end">
          <.spinner /> Validating...
          <.input_group_button class="ml-auto" variant="default">
            <LiveShadcn.Icon.icon name="arrow-up" />
            <span class="sr-only">Send</span>
          </.input_group_button>
        </.input_group_addon>
      </.input_group>
    </div>
    """
  end

  defp spinner_empty(assigns) do
    ~H"""
    <.empty class="w-full">
      <.empty_header>
        <.empty_media variant="icon"><.spinner /></.empty_media>
        <.empty_title>Processing your request</.empty_title>
        <.empty_description>
          Please wait while we process your request. Do not refresh the page.
        </.empty_description>
      </.empty_header>
      <.empty_content>
        <.button variant="outline" size="sm">Cancel</.button>
      </.empty_content>
    </.empty>
    """
  end

  defp spinner_rtl(assigns) do
    ~H"""
    <div class="flex w-full max-w-xs flex-col gap-4 [--radius:1rem]" dir="rtl">
      <.item variant="muted" dir="rtl">
        <.item_media><.spinner /></.item_media>
        <.item_content>
          <.item_title class="line-clamp-1">جاري معالجة الدفع...</.item_title>
        </.item_content>
        <.item_content class="flex-none justify-end">
          <span class="text-sm tabular-nums">١٠٠.٠٠ دولار</span>
        </.item_content>
      </.item>
    </div>
    """
  end

  defp data_table_default(assigns) do
    assigns =
      assign(assigns,
        labels: data_table_labels(:en),
        data: data_table_payments(assigns.data_table)
      )

    ~H"""
    <.data_table id="data-table" state={@data_table} data={@data} labels={@labels} />
    """
  end

  defp data_table_rtl(assigns) do
    assigns =
      assign(assigns,
        labels: data_table_labels(:ar),
        data: data_table_payments(assigns.data_table)
      )

    ~H"""
    <.data_table id="data-table-rtl" state={@data_table} data={@data} labels={@labels} dir="rtl" />
    """
  end

  attr :id, :string, required: true
  attr :state, :map, required: true
  attr :data, :list, required: true
  attr :labels, :map, required: true
  attr :dir, :string, default: nil

  defp data_table(assigns) do
    selected_count = Enum.count(assigns.data, &(&1.id in assigns.state.selected))

    selected_all? =
      assigns.data != [] and Enum.all?(assigns.data, &(&1.id in assigns.state.selected))

    assigns =
      assign(assigns,
        selected_count: selected_count,
        selected_all?: selected_all?,
        summary_of: " #{assigns.labels.of}",
        summary_suffix: " #{assigns.labels.rows_selected_suffix}"
      )

    ~H"""
    <div id={@id} class="w-full">
      <div class={
        if(@dir == "rtl", do: "flex items-center gap-2 py-4", else: "flex items-center py-4")
      }>
        <.input
          id={"#{@id}-filter"}
          value={@state.filter}
          placeholder={@labels.filter}
          class="max-w-sm"
          phx-hook="DataTableFilter"
          data-table-filter-event="data_table"
        />
        <.dropdown_menu
          id={"#{@id}-columns"}
          direct_trigger
          align={if(@dir == "rtl", do: "start", else: "end")}
          trigger_variant="outline"
          trigger_class={if(@dir == "rtl", do: "ms-auto", else: "ml-auto")}
          class={if(@dir == "rtl", do: nil, else: "w-44")}
          content_attrs={if(@dir == "rtl", do: %{"data-lang" => "ar"}, else: %{})}
          grouped
        >
          <:trigger>
            {@labels.columns} <LiveShadcn.Icon.icon name="chevron-down" />
          </:trigger>
          <:entry
            :for={column <- ["status", "email", "amount"]}
            kind="checkbox"
            value={column}
            checked={column in @state.visible}
            phx-click={
              Phoenix.LiveView.JS.push("data_table",
                value: %{action: "toggle-column", column: column}
              )
            }
            class="capitalize"
          >
            {column}
          </:entry>
        </.dropdown_menu>
      </div>
      <div class="overflow-hidden rounded-md border">
        <.table>
          <.table_header>
            <.table_row>
              <.table_head>
                <.checkbox
                  id={"#{@id}-select-all"}
                  checked={@selected_all?}
                  indeterminate={not @selected_all? and @selected_count > 0}
                  aria-label={@labels.select_all}
                  on_toggle={Phoenix.LiveView.JS.push("data_table", value: %{action: "toggle-all"})}
                  data-select-all
                />
              </.table_head>
              <.table_head :if={"status" in @state.visible}>{@labels.status}</.table_head>
              <.table_head :if={"email" in @state.visible}>
                <.button
                  variant="ghost"
                  phx-click={Phoenix.LiveView.JS.push("data_table", value: %{action: "sort"})}
                >
                  {@labels.email}<LiveShadcn.Icon.icon name="arrow-up-down" />
                </.button>
              </.table_head>
              <.table_head :if={"amount" in @state.visible}>
                <div class={if(@dir == "rtl", do: "text-start", else: "text-right")}>
                  {@labels.amount}
                </div>
              </.table_head>
              <.table_head></.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row
              :for={payment <- @data}
              data-state={if(payment.id in @state.selected, do: "selected")}
            >
              <.table_cell>
                <.checkbox
                  id={"#{@id}-#{payment.id}"}
                  checked={payment.id in @state.selected}
                  aria-label={@labels.select_row}
                  on_toggle={
                    Phoenix.LiveView.JS.push("data_table",
                      value: %{action: "toggle-row", id: payment.id}
                    )
                  }
                  data-row-id={payment.id}
                />
              </.table_cell>
              <.table_cell :if={"status" in @state.visible}>
                <div class="capitalize">{Map.fetch!(@labels.statuses, payment.status)}</div>
              </.table_cell>
              <.table_cell :if={"email" in @state.visible}>
                <div class="lowercase">{payment.email}</div>
              </.table_cell>
              <.table_cell :if={"amount" in @state.visible}>
                <div class={
                  if(@dir == "rtl", do: "text-start font-medium", else: "text-right font-medium")
                }>
                  {data_table_amount(payment.amount, @dir)}
                </div>
              </.table_cell>
              <.table_cell>
                <.dropdown_menu
                  id={"#{@id}-actions-#{payment.id}"}
                  direct_trigger
                  align={if(@dir == "rtl", do: "start", else: "end")}
                  trigger_variant="ghost"
                  trigger_size="icon-xs"
                  class={if(@dir == "rtl", do: "w-40", else: "w-44")}
                  content_attrs={if(@dir == "rtl", do: %{"data-lang" => "ar"}, else: %{})}
                  grouped
                >
                  <:trigger>
                    <span class="sr-only">{@labels.open_menu}</span><LiveShadcn.Icon.icon name="ellipsis" />
                  </:trigger>
                  <:entry kind="label">{@labels.actions}</:entry>
                  <:entry kind="item" value="copy-payment-id" clipboard={payment.id}>
                    {@labels.copy_payment_id}
                  </:entry>
                  <:entry kind="separator" />
                  <:entry kind="item" value="view-customer">{@labels.view_customer}</:entry>
                  <:entry kind="item" value="view-payment-details">
                    {@labels.view_payment_details}
                  </:entry>
                </.dropdown_menu>
              </.table_cell>
            </.table_row>
            <.table_row :if={@data == []}>
              <.table_cell colspan={2 + length(@state.visible)} class="h-24 text-center">
                {@labels.no_results}
              </.table_cell>
            </.table_row>
          </.table_body>
        </.table>
      </div>
      <.data_table_footer
        dir={@dir}
        id={@id}
        selected_count={@selected_count}
        labels={@labels}
        data_count={length(@data)}
        summary_of={@summary_of}
        summary_suffix={@summary_suffix}
      />
    </div>
    """
  end

  # The official React footer has intentional adjacent text and comment nodes.
  # Keep this small template formatter-stable so its DOM contract stays exact.
  defp data_table_footer(assigns) do
    ~H"""
    <div class={if(@dir == "rtl", do: "flex items-center justify-end gap-2 py-4", else: "flex items-center justify-end space-x-2 py-4")}><div :if={@dir == "rtl"} id={"#{@id}-summary"} class="flex-1 text-sm text-muted-foreground">{@selected_count}<!-- --> <!-- -->{@labels.of}<!-- --> <!-- -->{@data_count}<!-- --> <!-- -->{@labels.rows_selected_suffix}</div><div :if={@dir != "rtl"} id={"#{@id}-summary"} class="flex-1 text-sm text-muted-foreground">{@selected_count}<!-- -->{@summary_of}<!-- --> <!-- -->{@data_count}<!-- -->{@summary_suffix}</div><div class={if(@dir == "rtl", do: "flex gap-2", else: "space-x-2")}><.button variant="outline" size="sm" disabled>{@labels.previous}</.button><!-- --><.button variant="outline" size="sm" disabled>{@labels.next}</.button></div></div>
    """noformat
  end

  defp data_table_amount(amount, "rtl") do
    digits =
      amount
      |> Integer.to_string()
      |> String.graphemes()
      |> Enum.map_join(&arabic_digit/1)

    "\u200F#{digits}٫٠٠\u00A0US$"
  end

  defp data_table_amount(amount, _dir), do: "$#{amount}.00"

  defp arabic_digit(digit), do: Enum.at(~w(٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩), String.to_integer(digit))

  defp data_table_labels(:en) do
    %{
      filter: "Filter emails...",
      columns: "Columns",
      status: "Status",
      email: "Email",
      amount: "Amount",
      actions: "Actions",
      copy_payment_id: "Copy payment ID",
      view_customer: "View customer",
      view_payment_details: "View payment details",
      select_all: "Select all",
      select_row: "Select row",
      open_menu: "Open menu",
      no_results: "No results.",
      of: "of",
      rows_selected_suffix: "row(s) selected.",
      previous: "Previous",
      next: "Next",
      statuses: %{
        "success" => "success",
        "processing" => "processing",
        "failed" => "failed",
        "pending" => "pending"
      }
    }
  end

  defp data_table_labels(:ar) do
    %{
      filter: "تصفية البريد الإلكتروني...",
      columns: "الأعمدة",
      status: "الحالة",
      email: "البريد الإلكتروني",
      amount: "المبلغ",
      actions: "الإجراءات",
      copy_payment_id: "نسخ معرف الدفع",
      view_customer: "عرض العميل",
      view_payment_details: "عرض تفاصيل الدفع",
      select_all: "تحديد الكل",
      select_row: "تحديد الصف",
      open_menu: "فتح القائمة",
      no_results: "لا توجد نتائج.",
      of: "من",
      rows_selected_suffix: "صف(وف) محدد.",
      previous: "السابق",
      next: "التالي",
      statuses: %{
        "success" => "ناجح",
        "processing" => "قيد المعالجة",
        "failed" => "فشل",
        "pending" => "قيد الانتظار"
      }
    }
  end

  @table_invoices [
    %{invoice: "INV001", status: "Paid", amount: "$250.00", method: "Credit Card"},
    %{invoice: "INV002", status: "Pending", amount: "$150.00", method: "PayPal"},
    %{invoice: "INV003", status: "Unpaid", amount: "$350.00", method: "Bank Transfer"},
    %{invoice: "INV004", status: "Paid", amount: "$450.00", method: "Credit Card"},
    %{invoice: "INV005", status: "Paid", amount: "$550.00", method: "PayPal"},
    %{invoice: "INV006", status: "Pending", amount: "$200.00", method: "Bank Transfer"},
    %{invoice: "INV007", status: "Unpaid", amount: "$300.00", method: "Credit Card"}
  ]

  defp table_default(assigns) do
    assigns = assign(assigns, :invoices, @table_invoices)

    ~H"""
    <.table>
      <.table_caption>A list of your recent invoices.</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">Invoice</.table_head>
          <.table_head>Status</.table_head>
          <.table_head>Method</.table_head>
          <.table_head class="text-right">Amount</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={invoice <- @invoices}>
          <.table_cell class="font-medium">{invoice.invoice}</.table_cell>
          <.table_cell>{invoice.status}</.table_cell>
          <.table_cell>{invoice.method}</.table_cell>
          <.table_cell class="text-right">{invoice.amount}</.table_cell>
        </.table_row>
      </.table_body>
      <.table_footer>
        <.table_row>
          <.table_cell colspan="3">Total</.table_cell>
          <.table_cell class="text-right">$2,500.00</.table_cell>
        </.table_row>
      </.table_footer>
    </.table>
    """
  end

  defp table_footer_example(assigns) do
    assigns = assign(assigns, :invoices, Enum.take(@table_invoices, 3))

    ~H"""
    <.table>
      <.table_caption>A list of your recent invoices.</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">Invoice</.table_head>
          <.table_head>Status</.table_head>
          <.table_head>Method</.table_head>
          <.table_head class="text-right">Amount</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={invoice <- @invoices}>
          <.table_cell class="font-medium">{invoice.invoice}</.table_cell>
          <.table_cell>{invoice.status}</.table_cell>
          <.table_cell>{invoice.method}</.table_cell>
          <.table_cell class="text-right">{invoice.amount}</.table_cell>
        </.table_row>
      </.table_body>
      <.table_footer>
        <.table_row>
          <.table_cell colspan="3">Total</.table_cell>
          <.table_cell class="text-right">$2,500.00</.table_cell>
        </.table_row>
      </.table_footer>
    </.table>
    """
  end

  defp table_actions(assigns) do
    assigns =
      assign(assigns, :products, [
        %{id: "wireless-mouse", name: "Wireless Mouse", price: "$29.99"},
        %{id: "mechanical-keyboard", name: "Mechanical Keyboard", price: "$129.99"},
        %{id: "usb-c-hub", name: "USB-C Hub", price: "$49.99"}
      ])

    ~H"""
    <.table>
      <.table_header>
        <.table_row>
          <.table_head>Product</.table_head>
          <.table_head>Price</.table_head>
          <.table_head class="text-right">Actions</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={product <- @products}>
          <.table_cell class="font-medium">{product.name}</.table_cell>
          <.table_cell>{product.price}</.table_cell>
          <.table_cell class="text-right">
            <.dropdown_menu
              id={"table-actions-#{product.id}"}
              align="end"
              trigger_variant="ghost"
              trigger_size="icon"
              trigger_class="size-8"
            >
              <:trigger>
                <LiveShadcn.Icon.icon name="ellipsis" /><span class="sr-only">Open menu</span>
              </:trigger>
              <:entry kind="item" value="edit">Edit</:entry>
              <:entry kind="item" value="duplicate">Duplicate</:entry>
              <:entry kind="separator" />
              <:entry kind="item" value="delete" variant="destructive">Delete</:entry>
            </.dropdown_menu>
          </.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  defp table_rtl(assigns) do
    invoices =
      Enum.map(@table_invoices, fn invoice ->
        %{
          invoice
          | status:
              %{"Paid" => "مدفوع", "Pending" => "قيد الانتظار", "Unpaid" => "غير مدفوع"}[
                invoice.status
              ],
            method:
              %{
                "Credit Card" => "بطاقة ائتمانية",
                "PayPal" => "PayPal",
                "Bank Transfer" => "تحويل بنكي"
              }[invoice.method]
        }
      end)

    assigns = assign(assigns, :invoices, invoices)

    ~H"""
    <.table dir="rtl">
      <.table_caption>قائمة بفواتيرك الأخيرة.</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">الفاتورة</.table_head>
          <.table_head>الحالة</.table_head>
          <.table_head>الطريقة</.table_head>
          <.table_head class="text-right">المبلغ</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={invoice <- @invoices}>
          <.table_cell class="font-medium">{invoice.invoice}</.table_cell>
          <.table_cell>{invoice.status}</.table_cell>
          <.table_cell>{invoice.method}</.table_cell>
          <.table_cell class="text-right">{invoice.amount}</.table_cell>
        </.table_row>
      </.table_body>
      <.table_footer>
        <.table_row>
          <.table_cell colspan="3">المجموع</.table_cell>
          <.table_cell class="text-right">$2,500.00</.table_cell>
        </.table_row>
      </.table_footer>
    </.table>
    """
  end

  defp typography_demo(assigns), do: typography_story(assigns)

  defp typography_story(assigns) do
    ~H"""
    <div>
      <h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight text-balance">
        Taxing Laughter: The Joke Tax Chronicles
      </h1>
      <p class="text-xl leading-7 text-muted-foreground [&:not(:first-child)]:mt-6">
        Once upon a time, in a far-off land, there was a very lazy king who spent all day lounging on his throne. One day, his advisors came to him with a problem: the kingdom was running out of money.
      </p>
      <h2 class="mt-10 scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight transition-colors first:mt-0">
        The King's Plan
      </h2>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        The king thought long and hard, and finally came up with <a
          href="#"
          class="font-medium text-primary underline underline-offset-4"
        >a brilliant plan</a>: he would tax the jokes in the kingdom.
      </p>
      <blockquote class="mt-6 border-l-2 pl-6 italic">
        "After all," he said, "everyone enjoys a good joke, so it's only fair that they should pay for the privilege."
      </blockquote>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">The Joke Tax</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        The king's subjects were not amused. They grumbled and complained, but the king was firm:
      </p>
      <ul class="my-6 ml-6 list-disc [&>li]:mt-2">
        <li>1st level of puns: 5 gold coins</li>
        <li>2nd level of jokes: 10 gold coins</li>
        <li>3rd level of one-liners : 20 gold coins</li>
      </ul>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        As a result, people stopped telling jokes, and the kingdom fell into a gloom. But there was one person who refused to let the king's foolishness get him down: a court jester named Jokester.
      </p>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">Jokester's Revolt</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        Jokester began sneaking into the castle in the middle of the night and leaving jokes all over the place: under the king's pillow, in his soup, even in the royal toilet. The king was furious, but he couldn't seem to stop Jokester.
      </p>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        And then, one day, the people of the kingdom discovered that the jokes left by Jokester were so funny that they couldn't help but laugh. And once they started laughing, they couldn't stop.
      </p>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">The People's Rebellion</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        The people of the kingdom, feeling uplifted by the laughter, started to tell jokes and puns again, and soon the entire kingdom was in on the joke.
      </p>
      <div class="my-6 w-full overflow-y-auto">
        <table class="w-full">
          <thead>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <th class="border px-4 py-2 text-left font-bold [&[align=center]]:text-center [&[align=right]]:text-right">
                King's Treasury
              </th>
              <th class="border px-4 py-2 text-left font-bold [&[align=center]]:text-center [&[align=right]]:text-right">
                People's happiness
              </th>
            </tr>
          </thead>
          <tbody>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Empty
              </td>
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Overflowing
              </td>
            </tr>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Modest
              </td>
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Satisfied
              </td>
            </tr>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Full
              </td>
              <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
                Ecstatic
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        The king, seeing how much happier his subjects were, realized the error of his ways and repealed the joke tax. Jokester was declared a hero, and the kingdom lived happily ever after.
      </p>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        The moral of the story is: never underestimate the power of a good laugh and always be careful of bad ideas.
      </p>
    </div>
    """
  end

  defp typography_h1(assigns) do
    ~H"""
    <h1 class="scroll-m-20 text-center text-4xl font-extrabold tracking-tight text-balance">
      Taxing Laughter: The Joke Tax Chronicles
    </h1>
    """
  end

  defp typography_h2(assigns) do
    ~H"""
    <h2 class="scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight first:mt-0">
      The People of the Kingdom
    </h2>
    """
  end

  defp typography_h3(assigns) do
    ~H"""
    <h3 class="scroll-m-20 text-2xl font-semibold tracking-tight">The Joke Tax</h3>
    """
  end

  defp typography_h4(assigns) do
    ~H"""
    <h4 class="scroll-m-20 text-xl font-semibold tracking-tight">People stopped telling jokes</h4>
    """
  end

  defp typography_p(assigns) do
    ~H"""
    <p class="leading-7 [&:not(:first-child)]:mt-6">
      The king, seeing how much happier his subjects were, realized the error of his ways and repealed the joke tax.
    </p>
    """
  end

  defp typography_blockquote(assigns) do
    ~H"""
    <blockquote class="mt-6 border-l-2 pl-6 italic">
      "After all," he said, "everyone enjoys a good joke, so it's only fair that they should pay for the privilege."
    </blockquote>
    """
  end

  defp typography_table(assigns) do
    ~H"""
    <div class="my-6 w-full overflow-y-auto">
      <table class="w-full">
        <thead>
          <tr class="m-0 border-t p-0 even:bg-muted">
            <th class="border px-4 py-2 text-left font-bold [&[align=center]]:text-center [&[align=right]]:text-right">
              King's Treasury
            </th>
            <th class="border px-4 py-2 text-left font-bold [&[align=center]]:text-center [&[align=right]]:text-right">
              People's happiness
            </th>
          </tr>
        </thead>
        <tbody>
          <tr class="m-0 border-t p-0 even:bg-muted">
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Empty
            </td>
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Overflowing
            </td>
          </tr>
          <tr class="m-0 border-t p-0 even:bg-muted">
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Modest
            </td>
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Satisfied
            </td>
          </tr>
          <tr class="m-0 border-t p-0 even:bg-muted">
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Full
            </td>
            <td class="border px-4 py-2 text-left [&[align=center]]:text-center [&[align=right]]:text-right">
              Ecstatic
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp typography_list(assigns) do
    ~H"""
    <ul class="my-6 ml-6 list-disc [&>li]:mt-2">
      <li>1st level of puns: 5 gold coins</li>
      <li>2nd level of jokes: 10 gold coins</li>
      <li>3rd level of one-liners : 20 gold coins</li>
    </ul>
    """
  end

  defp typography_inline_code(assigns) do
    ~H"""
    <code class="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold">@radix-ui/react-alert-dialog</code>
    """
  end

  defp typography_lead(assigns) do
    ~H"""
    <p class="text-xl text-muted-foreground">
      A modal dialog that interrupts the user with important content and expects a response.
    </p>
    """
  end

  defp typography_large(assigns) do
    ~H"""
    <div class="text-lg font-semibold">Are you absolutely sure?</div>
    """
  end

  defp typography_small(assigns) do
    ~H"""
    <small class="text-sm leading-none font-medium">Email address</small>
    """
  end

  defp typography_muted(assigns) do
    ~H"""
    <p class="text-sm text-muted-foreground">Enter your email address.</p>
    """
  end

  defp typography_rtl(assigns), do: typography_rtl_story(assigns)

  defp typography_rtl_story(assigns) do
    ~H"""
    <div dir="rtl">
      <h1 class="scroll-m-20 text-4xl font-extrabold tracking-tight text-balance">
        فرض الضرائب على الضحك: سجلات ضريبة النكتة
      </h1>
      <p class="text-xl leading-7 text-muted-foreground [&:not(:first-child)]:mt-6">
        في قديم الزمان، في أرض بعيدة، كان هناك ملك كسول جداً يقضي يومه كله مستلقياً على عرشه. في أحد الأيام، جاءه مستشاروه بمشكلة: المملكة كانت تنفد من المال.
      </p>
      <h2 class="mt-10 scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight transition-colors first:mt-0">
        خطة الملك
      </h2>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        فكر الملك طويلاً وبجد، وأخيراً توصل إلى <a
          href="#"
          class="font-medium text-primary underline underline-offset-4"
        >خطة عبقرية</a>: سيفرض ضريبة على النكات في المملكة.
      </p>
      <blockquote class="mt-6 border-s-2 ps-6 italic">
        "في النهاية،" قال، "الجميع يستمتع بنكتة جيدة، لذا من العدل أن يدفعوا مقابل هذا الامتياز."
      </blockquote>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">ضريبة النكتة</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        لم يكن رعايا الملك سعداء. تذمروا واشتكوا، لكن الملك كان حازماً:
      </p>
      <ul class="my-6 ms-6 list-disc [&>li]:mt-2">
        <li>المستوى الأول من التورية: 5 قطع ذهبية</li>
        <li>المستوى الثاني من النكات: 10 قطع ذهبية</li>
        <li>المستوى الثالث من النكات القصيرة: 20 قطعة ذهبية</li>
      </ul>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        نتيجة لذلك، توقف الناس عن رواية النكات، وغرقت المملكة في الكآبة. لكن كان هناك شخص واحد رفض أن تحبطه حماقة الملك: مهرج البلاط المسمى المازح.
      </p>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">ثورة المازح</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        بدأ المازح يتسلل إلى القلعة في منتصف الليل ويترك النكات في كل مكان: تحت وسادة الملك، في حسائه، حتى في المرحاض الملكي. كان الملك غاضباً، لكنه لم يستطع إيقاف المازح.
      </p>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        وبعد ذلك، في يوم من الأيام، اكتشف سكان المملكة أن النكات التي تركها المازح كانت مضحكة جداً لدرجة أنهم لم يستطيعوا منع أنفسهم من الضحك. وبمجرد أن بدأوا بالضحك، لم يستطيعوا التوقف.
      </p>
      <h3 class="mt-8 scroll-m-20 text-2xl font-semibold tracking-tight">ثورة الشعب</h3>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        شعر سكان المملكة بالبهجة من الضحك، وبدأوا في رواية النكات والتورية مرة أخرى، وسرعان ما أصبحت المملكة بأكملها جزءاً من النكتة.
      </p>
      <div class="my-6 w-full overflow-y-auto">
        <table class="w-full">
          <thead>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <th class="border px-4 py-2 text-start font-bold">خزينة الملك</th>
              <th class="border px-4 py-2 text-start font-bold">سعادة الشعب</th>
            </tr>
          </thead>
          <tbody>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-start">فارغة</td>
              <td class="border px-4 py-2 text-start">فائضة</td>
            </tr>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-start">متواضعة</td>
              <td class="border px-4 py-2 text-start">راضٍ</td>
            </tr>
            <tr class="m-0 border-t p-0 even:bg-muted">
              <td class="border px-4 py-2 text-start">ممتلئة</td>
              <td class="border px-4 py-2 text-start">منتشٍ</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        الملك، عندما رأى مدى سعادة رعاياه، أدرك خطأ طرقه وألغى ضريبة النكتة. أُعلن المازح بطلاً، وعاشت المملكة في سعادة دائمة.
      </p>
      <p class="leading-7 [&:not(:first-child)]:mt-6">
        مغزى القصة هو: لا تستهن أبداً بقوة الضحك الجيد وكن دائماً حذراً من الأفكار السيئة.
      </p>
    </div>
    """
  end
end

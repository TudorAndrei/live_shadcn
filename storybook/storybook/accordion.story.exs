defmodule StorybookWeb.Storybook.Accordion do
  use PhoenixStorybook.Story, :component

  def function, do: &LiveShadcn.UI.Accordion.accordion/1

  def description do
    "A set of collapsible panels with headings. Generated from registry/spec/accordion.json."
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "One panel at a time, which is the Base UI default.",
        attributes: %{id: "story-faq", class: "max-w-80"},
        slots: [
          ~s|<:item id="story-faq-what" title="What is Base UI?">A library of unstyled components.</:item>|,
          ~s|<:item id="story-faq-start" title="How do I get started?">Read the quick start guide.</:item>|,
          ~s|<:item id="story-faq-use" title="Can I use it for my project?">Of course, it is open source.</:item>|
        ]
      },
      %Variation{
        id: :multiple,
        description: "Every panel opens independently.",
        attributes: %{id: "story-release", multiple: true, class: "max-w-80"},
        slots: [
          ~s|<:item id="story-release-added" title="Added">The disclosure recipe.</:item>|,
          ~s|<:item id="story-release-changed" title="Changed">The spec reads the style sheets too.</:item>|
        ]
      },
      %Variation{
        id: :open_and_disabled,
        description: "An item can start open, and an item can refuse interaction.",
        attributes: %{id: "story-states", multiple: true, class: "max-w-80"},
        slots: [
          ~s|<:item id="story-states-open" title="Open on first paint" open>Readable before any JavaScript has run.</:item>|,
          ~s|<:item id="story-states-disabled" title="Disabled" disabled>This panel cannot be opened.</:item>|
        ]
      }
    ]
  end
end

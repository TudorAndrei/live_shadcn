defmodule LiveAiElements.Components.AttachmentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveAiElements.Components.Attachments

  test "remove controls keep the pinned button classes for each attachment variant" do
    grid = render_remove("grid")
    inline = render_remove("inline")
    list = render_remove("list")

    assert_button_class(grid, [
      "inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium",
      "disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none",
      "[&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none",
      "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
      "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
      "aria-invalid:border-destructive hover:text-accent-foreground dark:hover:bg-accent/50",
      "has-[>svg]:px-3 absolute top-2 right-2 size-6 rounded-full p-0",
      "bg-background/80 backdrop-blur-sm opacity-0 transition-opacity",
      "group-hover:opacity-100 hover:bg-background [&>svg]:size-3"
    ])

    assert_button_class(inline, [
      "inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium",
      "disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none",
      "[&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none",
      "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
      "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
      "aria-invalid:border-destructive hover:bg-accent hover:text-accent-foreground",
      "dark:hover:bg-accent/50 has-[>svg]:px-3 size-5 rounded p-0 opacity-0",
      "transition-opacity group-hover:opacity-100 [&>svg]:size-2.5"
    ])

    assert_button_class(list, [
      "inline-flex items-center justify-center gap-2 whitespace-nowrap text-sm font-medium transition-all",
      "disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none",
      "[&_svg:not([class*='size-'])]:size-4 [&_svg]:shrink-0 outline-none",
      "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
      "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
      "aria-invalid:border-destructive hover:bg-accent hover:text-accent-foreground",
      "dark:hover:bg-accent/50 has-[>svg]:px-3 size-8 shrink-0 rounded p-0 [&>svg]:size-4"
    ])
  end

  test "the list remove control keeps the pinned icon button size" do
    html =
      render_component(&Attachments.attachment/1, %{
        data: %{filename: "mountain-landscape.jpg", mediaType: "image/jpeg"},
        variant: "list",
        on_remove: "remove_attachment",
        inner_block: []
      })

    assert html =~ ~s(aria-label="Remove")
    assert html =~ ~s(phx-click="remove_attachment")
    assert html =~ ~s(data-lb-attachment-remove="v1")
    refute html =~ "LiveAiElements.AttachmentRemove"
    assert html =~ "size-8"
    assert html =~ "p-0"
    refute html =~ "h-9"
    refute html =~ "px-4"
    refute html =~ "py-2"
    refute html =~ "!px-3"
  end

  test "attachment info has no empty class token" do
    html =
      render_component(&Attachments.attachment_info/1, %{
        data: %{filename: "mountain-landscape.jpg"},
        variant: "list",
        inner_block: []
      })

    assert html =~ ~s(class="min-w-0 flex-1")
    refute html =~ ~s(class="min-w-0 flex-1 ")
  end

  test "attachment empty has no empty class token" do
    html = render_component(&Attachments.attachment_empty/1, %{inner_block: []})

    assert html =~ ~s(class="flex items-center justify-center p-4 text-muted-foreground text-sm")
    refute html =~ ~s(class="flex items-center justify-center p-4 text-muted-foreground text-sm ")
  end

  test "parent scoped variant reaches the attachment without a repeated value" do
    html = render_component(&scoped_list_attachment/1, %{})

    assert html =~ "flex-col"
    assert html =~ "mountain-landscape.jpg"
    assert html =~ "image/jpeg"
  end

  test "inline attachment data without title filename or url uses fallback content" do
    source =
      render_component(&Attachments.attachment/1, %{
        data: %{id: "source", title: "React Documentation", type: "source-document"},
        variant: "inline",
        on_remove: nil,
        inner_block: []
      })

    unknown =
      render_component(&Attachments.attachment/1, %{
        data: %{id: "unknown"},
        variant: "inline",
        on_remove: nil,
        inner_block: []
      })

    assert source =~ "React Documentation"
    assert source =~ ~s(data-icon="globe")
    assert unknown =~ "Attachment"
    assert unknown =~ ~s(data-icon="paperclip")
  end

  test "remove control is absent without a parent action" do
    html =
      render_component(&Attachments.attachment/1, %{
        data: %{filename: "mountain-landscape.jpg", mediaType: "image/jpeg"},
        variant: "inline",
        on_remove: nil,
        inner_block: []
      })

    refute html =~ "aria-label=\"Remove\""
  end

  test "hover-card wrappers keep the public trigger and content composition" do
    html = render_component(&hover_card/1, %{})

    assert html =~ ~s(data-slot="hover-card-trigger")
    assert html =~ "Attachment trigger"
    assert html =~ ~s(data-slot="hover-card-content")
    assert html =~ "Attachment preview"
    assert html =~ "w-auto"
    assert html =~ "p-2"
    assert html =~ ~s(data-lb-open-delay="7")
    assert html =~ ~s(data-lb-positioner="attachment-preview-positioner")
    assert html =~ ~s(data-lb-align="end")
    assert html =~ ~s(data-lb-align-offset="0")
    assert html =~ ~s(data-trigger="attachment")
    assert html =~ ~s(data-content="attachment")

    assert html =~
             ~r/<div[^>]*data-slot="hover-card-trigger"[^>]*class="[^"]*trigger-child"[^>]*data-trigger="attachment"/s

    refute html =~ ~r/<span[^>]*data-slot="hover-card-trigger"/s

    assert html =~
             ~r/<div[^>]*data-slot="hover-card-content"[^>]*class="[^"]*content-child"[^>]*data-content="attachment"/s
  end

  test "hover-card trigger wraps ordinary slot content" do
    html = render_component(&ordinary_hover_card_trigger/1, %{})

    assert html =~
             ~r/<span[^>]*data-slot="hover-card-trigger"[^>]*class="ordinary-trigger"[^>]*data-trigger="ordinary"/s

    assert html =~ "Ordinary trigger"
  end

  defp hover_card(assigns) do
    ~H"""
    <Attachments.attachment_hover_card id="attachment-preview" align="end" delay={7} trigger_class="trigger-root" :let={hover_card}>
        <Attachments.attachment_hover_card_trigger
          id={hover_card.id}
          open={hover_card.open}
          delay={hover_card.delay}
          close_delay={hover_card.close_delay}
          variant={hover_card.trigger_variant}
          size={hover_card.trigger_size}
          as={hover_card.trigger_as}
          as_child
          class="trigger-child"
          data-trigger="attachment"
          :let={trigger}
        >
          <Attachments.attachment
            data={%{filename: "Attachment trigger"}}
            hover_card={trigger}
            variant="inline"
          >
            Attachment trigger
          </Attachments.attachment>
        </Attachments.attachment_hover_card_trigger>
      <Attachments.attachment_hover_card_content
        id={hover_card.id}
        open={hover_card.open}
        side={hover_card.side}
        align={hover_card.align}
        offset={hover_card.offset}
        autofocus={hover_card.autofocus}
        dir={hover_card.dir}
        align_offset={hover_card.align_offset}
        class="content-child"
        data-content="attachment"
      >
        Attachment preview
      </Attachments.attachment_hover_card_content>
    </Attachments.attachment_hover_card>
    """
  end

  defp scoped_list_attachment(assigns) do
    ~H"""
    <Attachments.attachments variant="list" :let={attachments}>
      <Attachments.attachment
        data={%{filename: "mountain-landscape.jpg", mediaType: "image/jpeg"}}
        variant={attachments.variant}
        on_remove="remove_attachment"
      />
    </Attachments.attachments>
    """
  end

  defp ordinary_hover_card_trigger(assigns) do
    ~H"""
    <Attachments.attachment_hover_card_trigger
      id="ordinary-preview"
      class="ordinary-trigger"
      data-trigger="ordinary"
    >
      Ordinary trigger
    </Attachments.attachment_hover_card_trigger>
    """
  end

  defp render_remove(variant) do
    render_component(&Attachments.attachment_remove/1, %{
      on_remove: "remove_attachment",
      variant: variant,
      inner_block: []
    })
  end

  defp assert_button_class(html, expected) do
    [_, class] = Regex.run(~r/<button[^>]*class="([^"]+)"/, html)

    escaped_expected =
      expected
      |> Enum.join(" ")
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    assert class == escaped_expected
  end
end

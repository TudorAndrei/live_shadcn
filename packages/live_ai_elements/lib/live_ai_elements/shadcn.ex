defmodule LiveAiElements.Shadcn do
  @moduledoc false

  @button_base "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"

  @button_variants %{
    "default" => "bg-primary text-primary-foreground hover:bg-primary/90",
    "destructive" =>
      "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
    "outline" =>
      "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50",
    "secondary" => "bg-secondary text-secondary-foreground hover:bg-secondary/80",
    "ghost" => "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
    "link" => "text-primary underline-offset-4 hover:underline"
  }

  @button_sizes %{
    "default" => "h-9 px-4 py-2 has-[>svg]:px-3",
    "sm" => "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
    "lg" => "h-10 rounded-md px-6 has-[>svg]:px-4",
    "icon" => "size-9",
    "icon-sm" => "size-8",
    "icon-lg" => "size-10"
  }

  @button_group_base "flex w-fit items-stretch [&>*]:focus-visible:z-10 [&>*]:focus-visible:relative [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1 has-[select[aria-hidden=true]:last-child]:[&>[data-slot=select-trigger]:last-of-type]:rounded-r-md has-[>[data-slot=button-group]]:gap-2"
  @button_group_orientations %{
    "horizontal" =>
      "[&>*:not(:first-child)]:rounded-l-none [&>*:not(:first-child)]:border-l-0 [&>*:not(:last-child)]:rounded-r-none",
    "vertical" =>
      "flex-col [&>*:not(:first-child)]:rounded-t-none [&>*:not(:first-child)]:border-t-0 [&>*:not(:last-child)]:rounded-b-none"
  }
  @button_group_text "bg-muted flex items-center gap-2 rounded-md border px-4 text-sm font-medium shadow-xs [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4"
  @badge_base "inline-flex items-center justify-center rounded-full border px-2 py-0.5 text-xs font-medium w-fit whitespace-nowrap shrink-0 [&>svg]:size-3 gap-1 [&>svg]:pointer-events-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive transition-[color,box-shadow] overflow-hidden"
  @badge_variants %{
    "default" => "border-transparent bg-primary text-primary-foreground [a&]:hover:bg-primary/90",
    "secondary" =>
      "border-transparent bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/90",
    "destructive" =>
      "border-transparent bg-destructive text-white [a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
    "outline" => "text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground"
  }

  @card_classes %{
    card: "bg-card text-card-foreground flex flex-col gap-6 rounded-xl border py-6 shadow-sm",
    header:
      "@container/card-header grid auto-rows-min grid-rows-[auto_auto] items-start gap-2 px-6 has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-6",
    title: "leading-none font-semibold",
    description: "text-muted-foreground text-sm",
    action: "col-start-2 row-span-2 row-start-1 self-start justify-self-end",
    content: "px-6",
    footer: "flex items-center px-6 [.border-t]:pt-6"
  }
  @alert_base "relative w-full rounded-lg border px-4 py-3 text-sm grid has-[>svg]:grid-cols-[calc(var(--spacing)*4)_1fr] grid-cols-[0_1fr] has-[>svg]:gap-x-3 gap-y-0.5 items-start [&>svg]:size-4 [&>svg]:translate-y-0.5 [&>svg]:text-current"
  @alert_variants %{
    "default" => "bg-card text-card-foreground",
    "destructive" =>
      "text-destructive bg-card [&>svg]:text-current *:data-[slot=alert-description]:text-destructive/90"
  }
  @input "file:text-foreground placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"
  @textarea "border-input placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:bg-input/30 flex field-sizing-content min-h-16 w-full rounded-md border bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50 md:text-sm"
  @switch "peer data-[state=checked]:bg-primary data-[state=unchecked]:bg-input focus-visible:border-ring focus-visible:ring-ring/50 dark:data-[state=unchecked]:bg-input/80 inline-flex h-[1.15rem] w-8 shrink-0 items-center rounded-full border border-transparent shadow-xs transition-all outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50"
  @switch_thumb "bg-background dark:data-[state=unchecked]:bg-foreground dark:data-[state=checked]:bg-primary-foreground pointer-events-none block size-4 rounded-full ring-0 transition-transform data-[state=checked]:translate-x-[calc(100%-2px)] data-[state=unchecked]:translate-x-0"
  @input_group "group/input-group border-input dark:bg-input/30 relative flex w-full items-center rounded-md border shadow-xs transition-[color,box-shadow] outline-none h-9 min-w-0 has-[>textarea]:h-auto has-[>[data-align=inline-start]]:[&>input]:pl-2 has-[>[data-align=inline-end]]:[&>input]:pr-2 has-[>[data-align=block-start]]:h-auto has-[>[data-align=block-start]]:flex-col has-[>[data-align=block-start]]:[&>input]:pb-3 has-[>[data-align=block-end]]:h-auto has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-end]]:[&>input]:pt-3 has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50 has-[[data-slot=input-group-control]:focus-visible]:ring-[3px] has-[[data-slot][aria-invalid=true]]:ring-destructive/20 has-[[data-slot][aria-invalid=true]]:border-destructive dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40"
  @input_group_addon "text-muted-foreground flex h-auto cursor-text items-center justify-center gap-2 py-1.5 text-sm font-medium select-none [&>svg:not([class*=size-])]:size-4 [&>kbd]:rounded-[calc(var(--radius)-5px)] group-data-[disabled=true]/input-group:opacity-50"
  @input_group_text "text-muted-foreground flex items-center gap-2 text-sm [&_svg]:pointer-events-none [&_svg:not([class*=size-])]:size-4"
  @input_group_input "flex-1 rounded-none border-0 bg-transparent shadow-none! focus-visible:ring-0 dark:bg-transparent"
  @input_group_button "text-sm shadow-none flex min-w-0 gap-2 items-center"
  @input_group_button_sizes %{
    "xs" =>
      "h-6 gap-1 px-2 rounded-[calc(var(--radius)-5px)] [&>svg:not([class*=size-])]:size-3.5 has-[>svg]:px-2",
    "sm" => "h-8 px-2.5 gap-1.5 rounded-md has-[>svg]:px-2.5",
    "icon-xs" => "size-6 rounded-[calc(var(--radius)-5px)] p-0 has-[>svg]:p-0",
    "icon-sm" => "!size-8 !p-0 has-[>svg]:p-0"
  }
  @input_group_addon_align %{
    "inline-start" => "order-first pl-3 has-[>button]:ml-[-0.45rem] has-[>kbd]:ml-[-0.35rem]",
    "inline-end" => "order-last pr-3 has-[>button]:mr-[-0.45rem] has-[>kbd]:mr-[-0.35rem]",
    "block-start" =>
      "order-first w-full justify-start px-3 pt-3 [.border-b]:pb-3 group-has-[>input]/input-group:pt-2.5",
    "block-end" =>
      "order-last w-full justify-start px-3 pb-3 [.border-t]:pt-3 group-has-[>input]/input-group:pb-2.5"
  }

  def alert_class(variant \\ "default"),
    do: @alert_base <> " " <> Map.fetch!(@alert_variants, variant)

  def button_class(size \\ "default", variant \\ "default") do
    [@button_base, Map.fetch!(@button_variants, variant), Map.fetch!(@button_sizes, size)]
    |> Enum.join(" ")
  end

  def button_group_class(orientation \\ "horizontal") do
    @button_group_base <> " " <> Map.fetch!(@button_group_orientations, orientation)
  end

  def button_group_text_class, do: @button_group_text
  def badge_class(nil), do: @badge_base
  def badge_class(variant), do: @badge_base <> " " <> Map.fetch!(@badge_variants, variant)
  def card_class(part), do: Map.fetch!(@card_classes, part)
  def input_class, do: @input
  def input_group_class, do: @input_group
  def input_group_input_class, do: @input <> " " <> @input_group_input
  def input_group_text_class, do: @input_group_text

  def input_group_button_class(size \\ "xs", variant \\ "ghost") do
    button_class("default", variant) <>
      " !flex " <> @input_group_button <> " " <> Map.fetch!(@input_group_button_sizes, size)
  end

  def input_group_addon_class(align),
    do: @input_group_addon <> " " <> Map.fetch!(@input_group_addon_align, align)

  def switch_class, do: @switch
  def switch_thumb_class, do: @switch_thumb
  def textarea_class, do: @textarea
end

defmodule LiveAiElements.Components.MicSelector do
  @moduledoc """
  Mic selector. Built on `shadcn/button`, `shadcn/command`, `shadcn/input-group`, `shadcn/popover`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/buttonVariants/base" =>
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "cva/buttonVariants/default/size" => "default",
    "cva/buttonVariants/variant/size/default" => "cn-button-size-default",
    "cva/buttonVariants/variant/size/icon" => "cn-button-size-icon",
    "cva/buttonVariants/variant/size/icon-lg" => "cn-button-size-icon-lg",
    "cva/buttonVariants/variant/size/icon-sm" => "cn-button-size-icon-sm",
    "cva/buttonVariants/variant/size/icon-xs" => "cn-button-size-icon-xs",
    "cva/buttonVariants/variant/size/lg" => "cn-button-size-lg",
    "cva/buttonVariants/variant/size/sm" => "cn-button-size-sm",
    "cva/buttonVariants/variant/size/xs" => "cn-button-size-xs",
    "cva/buttonVariants/variant/variant/default" => "cn-button-variant-default",
    "cva/buttonVariants/variant/variant/destructive" => "cn-button-variant-destructive",
    "cva/buttonVariants/variant/variant/ghost" => "cn-button-variant-ghost",
    "cva/buttonVariants/variant/variant/link" => "cn-button-variant-link",
    "cva/buttonVariants/variant/variant/outline" => "cn-button-variant-outline",
    "cva/buttonVariants/variant/variant/secondary" => "cn-button-variant-secondary",
    "cva/inputGroupAddonVariants/variant/align/block-end" =>
      "cn-input-group-addon-align-block-end order-last w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/block-start" =>
      "cn-input-group-addon-align-block-start order-first w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/inline-end" =>
      "cn-input-group-addon-align-inline-end order-last",
    "cva/inputGroupAddonVariants/variant/align/inline-start" =>
      "cn-input-group-addon-align-inline-start order-first",
    "cva/inputGroupButtonVariants/variant/size/icon-sm" => "cn-input-group-button-size-icon-sm",
    "cva/inputGroupButtonVariants/variant/size/icon-xs" => "cn-input-group-button-size-icon-xs",
    "cva/inputGroupButtonVariants/variant/size/sm" => "cn-input-group-button-size-sm",
    "cva/inputGroupButtonVariants/variant/size/xs" => "cn-input-group-button-size-xs",
    "jsx/Command/class/0" => "cn-command flex size-full flex-col overflow-hidden",
    "jsx/CommandItem/class/0" =>
      "cn-command-item group/command-item data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/CommandItem/class/1" =>
      "cn-command-item-indicator ml-auto opacity-0 group-has-data-[slot=command-shortcut]/command-item:hidden group-data-[checked=true]/command-item:opacity-100",
    "jsx/MicSelectorContent/class/0" => "p-0",
    "jsx/MicSelectorTrigger/class/0" => "shrink-0 text-muted-foreground",
    "jsx/PopoverContent/class/0" => "isolate z-50",
    "jsx/PopoverContent/class/1" =>
      "cn-popover-content cn-popover-content-logical z-50 w-72 origin-(--transform-origin) outline-hidden"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                        [table, "variant", group, choice] <- [String.split(path, "/")],
                        reduce: %{} do
                      variants ->
                        put_in(
                          variants,
                          [
                            Access.key(table, %{}),
                            Access.key(group, %{}),
                            Access.key(choice, nil)
                          ],
                          value
                        )
                    end)

  alias LiveBase.FormControl
  alias LiveBase.Listbox
  alias LiveBase.Popover

  @doc """
  Built on `shadcn/button`, `shadcn/command`, `shadcn/input-group`, `shadcn/popover`.

      <.mic_selector id="style" field={@form[:style]}>
        <:option value="vega" label="Vega" />
        <:option value="nova" label="Nova" />
      </.mic_selector>

  The trigger is a button, and a button submits nothing, so there is a hidden
  input beside it carrying the chosen value. Choosing runs on the client and
  fires `change`, so `phx-change` still sees it.
  """
  attr(:id, :string, required: true, doc: "Every id inside the listbox derives from it.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
  )

  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "The chosen value.")

  attr(:placeholder, :string,
    default: "Select…",
    doc: "What the trigger reads with nothing chosen."
  )

  attr(:labelledby, :string, default: nil, doc: "The id of the label that names it.")
  attr(:errors, :list, default: [])
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4)
  attr(:class, :any, default: nil, doc: "Appended to the list's class string.")
  attr(:list_class, :any, default: nil)
  attr(:item_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:align_offset, :string, default: "0")
  attr(:data, :string, default: nil)
  attr(:default_open, :boolean, default: false)
  attr(:default_value, :string, default: nil)
  attr(:popover_options, :string, default: nil)
  attr(:side_offset, :string, default: "4")

  attr(:size, :string,
    default: @upstream_facts["cva/buttonVariants/default/size"],
    values: @variant_classes |> get_in(["buttonVariants", "size"]) |> Map.keys() |> Enum.sort()
  )

  attr(:variant, :string,
    default: "outline",
    values: @variant_classes |> get_in(["buttonVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:width, :any, default: nil)
  attr(:rest, :global)

  slot :option, doc: "One value to choose." do
    attr(:value, :string, required: true, doc: "Unique. What the form submits.")
    attr(:label, :string, doc: "What it reads. Defaults to the value.")
    attr(:disabled, :boolean)
  end

  slot(:inner_block, doc: "Anything the options do not cover.")

  def mic_selector(assigns) do
    assigns = FormControl.from_field(assigns)

    ~H"""
    <div
      id={@id}
      phx-hook="LiveAiElements.MicSelector"
      class="contents"
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      {@rest}
    >
      <button
        data-slot="popover-trigger"
        id={Popover.trigger_id(@id)}
        type="button"
        aria-labelledby={@labelledby}
        aria-haspopup="dialog"
        aria-expanded={to_string(@open)}
        aria-controls={Popover.popup_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-popup-open={flag(@open)}
        data-pressed={flag(@open)}
        aria-invalid={if(@errors != [], do: "true")}
        class={[
          Shadcn.button_class(@size, @variant),
          @trigger_class
        ]}
      >
        <span
          id={Listbox.value_id(@id)}
          data-lb-mic-value
          phx-mounted={Listbox.owned_attributes(:value)}
          class="flex-1 text-left"
        >
          {label(@option, @value) || @placeholder}
        </span>
        <LiveShadcn.Icon.icon
          name="chevrons-up-down"
          width="16"
          height="16"
          class={upstream_fact("jsx/MicSelectorTrigger/class/0")}
        />
      </button>
      <input
        type="hidden"
        id={Listbox.input_id(@id)}
        name={@name}
        value={@value}
        disabled={@disabled}
        required={@required}
        phx-mounted={Listbox.owned_attributes(:input)}
      />
      <div class="contents">
        <div
          id={Popover.positioner_id(@id)}
          hidden={not @open}
          phx-hook={Popover.hook()}
          data-lb-anchor={Popover.trigger_id(@id)}
          data-lb-side={@side}
          data-lb-align={@align}
          data-lb-offset={@side_offset}
          data-lb-align-offset={@align_offset}
          data-lb-autofocus
          phx-mounted={Popover.owned_attributes(:positioner)}
          data-open={flag(@open)}
          data-closed={flag(not @open)}
          class={upstream_fact("jsx/PopoverContent/class/0")}
        >
          <div
            data-slot="popover-content"
            id={Popover.popup_id(@id)}
            role="dialog"
            tabindex="-1"
            hidden={not @open}
            data-lb-popup
            phx-mounted={Popover.owned_attributes(:popup)}
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            class={[
              upstream_fact("jsx/PopoverContent/class/1"),
              upstream_fact("jsx/MicSelectorContent/class/0"),
              "static! block! flex-row! [gap:normal]! border bg-popover! p-0! text-base! leading-6! ring-0! before:hidden!",
              (@class || "")
            ]}
            data-lb-style-target
            data-lb-measure
            style="width: var(--anchor-width)"
          >
            <div
              data-slot="command"
              class="bg-popover text-popover-foreground flex h-full w-full flex-col overflow-hidden rounded-md"
            >
              <div
                data-slot="command-input-wrapper"
                class="flex h-9 items-center gap-2 border-b px-3"
              >
                <LiveShadcn.Icon.icon name="search" class="size-4 shrink-0 opacity-50" />
                <input
                  data-slot="command-input"
                  role="combobox"
                  aria-expanded="true"
                  aria-label="Search microphones"
                  placeholder="Search microphones..."
                  class="placeholder:text-muted-foreground flex h-10 w-full rounded-md bg-transparent py-3 text-sm outline-hidden disabled:cursor-not-allowed disabled:opacity-50"
                />
              </div>
              <div
                data-slot="command-list"
                role="listbox"
                class="max-h-[300px] scroll-py-1 overflow-x-hidden overflow-y-auto"
              >
                <div
                  :for={{option, index} <- Enum.with_index(@option)}
                  id={Listbox.option_id(@id, option[:value])}
                  data-slot="command-item"
                  role="option"
                  aria-disabled={to_string(option[:disabled] == true)}
                  aria-selected={to_string(index == 0)}
                  tabindex="-1"
                  data-selected={to_string(index == 0)}
                  phx-click={
                    if(option[:disabled] != true,
                      do:
                        Listbox.choose(
                          listbox: @id,
                          value: option[:value],
                          label: option[:label]
                        )
                    )
                  }
                  phx-mounted={Listbox.owned_attributes(:option)}
                  data-disabled={to_string(option[:disabled] == true)}
                  class={[
                    "data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground [&_svg:not([class*='text-'])]:text-muted-foreground relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
                    @item_class
                  ]}
                  data-lb-style-target
                >
                  {option[:label] || option[:value]}
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  # What the trigger reads before anything has been chosen, and after.
  defp label(options, value) do
    case Enum.find(options, &(&1[:value] == value)) do
      nil -> nil
      option -> option[:label] || option[:value]
    end
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end

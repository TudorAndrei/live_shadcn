defmodule LiveShadcnTools.ConverterTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Converter

  @source ~S'''
  import { cn } from "@/lib/utils"

  function Button({ className }) {
    return <button className={cn("inline-flex px-2", className)} />
  }

  export { Button }
  '''

  @port ~S'''
  defmodule LiveShadcn.UI.Button do
    use Phoenix.Component

    # live-shadcn: upstream facts start
    @upstream_facts %{
      "jsx/Button/class/0" => "inline-flex px-2"
    }
    # live-shadcn: upstream facts end

    defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

    attr :class, :any, default: nil

    def button(assigns) do
      ~H"""
      <button class={[upstream_fact("jsx/Button/class/0"), @class]} />
      """
    end
  end
  '''

  test "the same source and port produce the same contract bytes" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, artifact, changes} = Converter.sync(input)
    assert changes == [%{kind: :contract, path: "registry/spec/shadcn/button.json"}]
    assert artifact.contract["schema_version"] == 2
    assert artifact.contract["facts"] == %{"jsx/Button/class/0" => "inline-flex px-2"}
    assert artifact.port == @port

    assert {:current, current} =
             Converter.sync(%{input | contract: artifact.contract, port: artifact.port})

    assert current.contract_json == artifact.contract_json
    assert current.port == artifact.port
  end

  test "a class-only change updates the fact block and names the changed fact" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)
    changed_source = String.replace(@source, "inline-flex px-2", "inline-flex px-3")

    assert {:updated, updated, changes} =
             Converter.sync(%{
               input
               | files: %{"shadcn/ui/button.tsx" => changed_source},
                 contract: current.contract,
                 port: current.port
             })

    assert changes == [
             %{
               kind: :fact,
               key: "jsx/Button/class/0",
               before: "inline-flex px-2",
               after: "inline-flex px-3"
             }
           ]

    assert updated.port =~ ~s|"jsx/Button/class/0" => "inline-flex px-3"|
    refute updated.port =~ "inline-flex px-2"
  end

  test "a JSX structure change needs a manual port update" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)
    changed_source = String.replace(@source, "<button", "<section")

    assert {:manual, [drift]} =
             Converter.sync(%{
               input
               | files: %{"shadcn/ui/button.tsx" => changed_source},
                 contract: current.contract,
                 port: current.port
             })

    assert drift.kind == :structure
    assert drift.path == "shadcn/ui/button.tsx"
  end

  test "a new class state read needs a manual behavior update" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)

    changed_source =
      String.replace(@source, "inline-flex px-2", "inline-flex px-2 data-active:bg-primary")

    assert {:manual, [drift]} =
             Converter.sync(%{
               input
               | files: %{"shadcn/ui/button.tsx" => changed_source},
                 contract: current.contract,
                 port: current.port
             })

    assert drift == %{
             kind: :state_reads,
             before: [],
             after: [%{"name" => "data-active", "value" => nil}]
           }
  end

  test "CVA values and defaults are safe facts" do
    source = ~S'''
    import { cva } from "class-variance-authority"

    const buttonVariants = cva("base", {
      variants: {
        tone: {
          default: "tone-default",
          quiet: "tone-quiet",
        },
      },
      defaultVariants: { tone: "default" },
    })

    function Button({ tone }) {
      return <button className={buttonVariants({ tone })} />
    }

    export { Button, buttonVariants }
    '''

    port = ~S'''
    defmodule LiveShadcn.UI.Button do
      use Phoenix.Component

      # live-shadcn: upstream facts start
      @upstream_facts %{
        "cva/buttonVariants/base" => "base",
        "cva/buttonVariants/default/tone" => "default",
        "cva/buttonVariants/variant/tone/default" => "tone-default",
        "cva/buttonVariants/variant/tone/quiet" => "tone-quiet"
      }
      # live-shadcn: upstream facts end

      @tones for {"cva/buttonVariants/variant/tone/" <> value, _class} <- @upstream_facts,
                 do: value

      attr :tone, :string,
        default: @upstream_facts["cva/buttonVariants/default/tone"],
        values: @tones
    end
    '''

    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: port
    }

    assert {:updated, current, _changes} = Converter.sync(input)

    changed_source =
      source
      |> String.replace(
        "quiet: \"tone-quiet\",",
        "quiet: \"tone-muted\",\n        loud: \"tone-loud\","
      )
      |> String.replace(~s|tone: "default"|, ~s|tone: "quiet"|)

    assert {:updated, updated, changes} =
             Converter.sync(%{
               input
               | files: %{"shadcn/ui/button.tsx" => changed_source},
                 contract: current.contract,
                 port: current.port
             })

    assert Enum.any?(changes, &(&1.key == "cva/buttonVariants/variant/tone/loud"))
    assert Enum.any?(changes, &(&1.key == "cva/buttonVariants/default/tone"))
    assert updated.port =~ ~s|"cva/buttonVariants/variant/tone/loud" => "tone-loud"|
    assert updated.port =~ ~s|"cva/buttonVariants/default/tone" => "quiet"|
  end

  test "a TSX parse error names the file and byte span" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => "function Broken( {\n"},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:error, [diagnostic]} = Converter.sync(input)
    assert diagnostic["path"] == "shadcn/ui/button.tsx"
    assert diagnostic["message"] =~ "Expected `}`"
    assert diagnostic["start"] == 19
    assert diagnostic["end"] == 19
  end

  test "the offline check rejects an unrecorded port body edit" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)

    edited_port =
      String.replace(current.port, "attr :class", "attr :extra, :string\n\n  attr :class")

    assert {:error, [diagnostic]} =
             Converter.sync(
               Map.merge(input, %{
                 mode: :offline,
                 files: %{},
                 contract: current.contract,
                 port: edited_port
               })
             )

    assert diagnostic.kind == :port_body

    assert {:updated, recorded, [%{kind: :port_body}]} =
             Converter.sync(%{input | contract: current.contract, port: edited_port})

    assert recorded.port == edited_port

    assert {:current, _artifact} =
             Converter.sync(
               Map.merge(input, %{
                 mode: :offline,
                 files: %{},
                 contract: recorded.contract,
                 port: recorded.port
               })
             )
  end

  test "a Base UI contract change needs manual review" do
    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => @source},
      styles: %{},
      base_ui: %{"button" => "Button data attributes: data-disabled"},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)

    assert {:manual, [drift]} =
             Converter.sync(%{
               input
               | base_ui: %{"button" => "Button data attributes: data-disabled, data-active"},
                 contract: current.contract,
                 port: current.port
             })

    assert drift == %{kind: :base_ui, path: "button"}
  end

  test "a style change that adds a state read needs manual review" do
    source = String.replace(@source, "inline-flex px-2", "cn-button inline-flex px-2")

    input = %{
      source: "shadcn",
      name: "button",
      files: %{"shadcn/ui/button.tsx" => source},
      styles: %{"vega" => %{"cn-button" => "px-2"}},
      base_ui: %{},
      contract: nil,
      port: @port
    }

    assert {:updated, current, _changes} = Converter.sync(input)

    assert {:manual, [%{kind: :state_reads, after: reads}]} =
             Converter.sync(%{
               input
               | styles: %{"vega" => %{"cn-button" => "px-2 data-active:bg-primary"}},
                 contract: current.contract,
                 port: current.port
             })

    assert %{"name" => "data-active", "value" => nil} in reads
  end

  test "class facts include cn calls outside a className attribute" do
    source = ~S'''
    function Calendar({ defaults }) {
      const classNames = {
        root: cn("calendar-root", defaults.root),
        day: cn("calendar-day", defaults.day),
      }

      return <DayPicker classNames={classNames} />
    }

    export { Calendar }
    '''

    port = ~S'''
    defmodule LiveShadcn.UI.Calendar do
      # live-shadcn: upstream facts start
      @upstream_facts %{
        "jsx/Calendar/class/0" => "calendar-root",
        "jsx/Calendar/class/1" => "calendar-day"
      }
      # live-shadcn: upstream facts end
    end
    '''

    assert {:updated, artifact, _changes} =
             Converter.sync(%{
               source: "shadcn",
               name: "calendar",
               files: %{"shadcn/ui/calendar.tsx" => source},
               styles: %{},
               base_ui: %{},
               contract: nil,
               port: port
             })

    assert artifact.contract["facts"] == %{
             "jsx/Calendar/class/0" => "calendar-root",
             "jsx/Calendar/class/1" => "calendar-day"
           }
  end

  test "a static String.raw class template is a safe fact" do
    source = ~S'''
    function Calendar() {
      return <div className={cn(String.raw`rtl:[.next\_icon]:rotate-180`)} />
    }

    export { Calendar }
    '''

    port = ~S'''
    defmodule LiveShadcn.UI.Calendar do
      # live-shadcn: upstream facts start
      @upstream_facts %{
        "jsx/Calendar/class/0" => "rtl:[.next\\_icon]:rotate-180"
      }
      # live-shadcn: upstream facts end
    end
    '''

    assert {:updated, artifact, _changes} =
             Converter.sync(%{
               source: "shadcn",
               name: "calendar",
               files: %{"shadcn/ui/calendar.tsx" => source},
               styles: %{},
               base_ui: %{},
               contract: nil,
               port: port
             })

    assert artifact.contract["facts"] == %{
             "jsx/Calendar/class/0" => "rtl:[.next\\_icon]:rotate-180"
           }
  end

  test "a binding joins a source fact with a reviewed literal" do
    port = ~S'''
    defmodule LiveShadcn.UI.Calendar do
      # live-shadcn: upstream facts start
      @upstream_facts %{
        "port/calendar/root" => "inline-flex rdp-root"
      }
      # live-shadcn: upstream facts end

      defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)
      def root_class, do: upstream_fact("port/calendar/root")
    end
    '''

    bindings = %{
      "copy" => [],
      "derived" => %{
        "port/calendar/root" => %{
          "op" => "join",
          "items" => [
            %{"fact" => "jsx/Button/class/0"},
            %{"literal" => "rdp-root"}
          ]
        }
      }
    }

    assert {:updated, artifact, _changes} =
             Converter.sync(%{
               source: "shadcn",
               name: "calendar",
               files: %{"shadcn/ui/calendar.tsx" => @source},
               styles: %{},
               base_ui: %{},
               bindings: bindings,
               ignored: %{},
               contract: nil,
               port: String.replace(port, "inline-flex rdp-root", "inline-flex px-2 rdp-root")
             })

    assert artifact.contract["bindings"] == bindings

    assert artifact.contract["facts"] == %{
             "port/calendar/root" => "inline-flex px-2 rdp-root"
           }
  end
end

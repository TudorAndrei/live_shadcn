defmodule LiveShadcnTools.UiHooksTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Ui.Hooks

  setup do
    root = Path.join(System.tmp_dir!(), "ui-hooks-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(root) end)
    File.mkdir_p!(Path.join(root, "registry"))

    js = Path.join(root, "packages/live_base/assets/js")
    File.mkdir_p!(js)

    File.write!(Path.join(js, "helper.js"), """
    export function label(el) {
      return el.dataset.label;
    }

    export function unused() {
      return "not in the bundle";
    }
    """)

    File.write!(Path.join(js, "widget.js"), """
    import { animate } from "motion";
    import { label } from "./helper.js";

    export const Widget = {
      mounted() {
        animate(this.el, { opacity: 1 });
        this.el.title = label(this.el);
      },
    };

    export const Other = {};
    """)

    lib = Path.join(root, "packages/live_base/lib")
    File.mkdir_p!(lib)
    component = Path.join(lib, "widget.ex")

    File.write!(component, """
    defmodule Widget do
      use Phoenix.Component

      def widget(assigns) do
        ~H\"\"\"
        <div phx-hook=".Widget"></div>
        <%!-- colocated-hook widget.js#Widget --%>
        <%!-- /colocated-hook --%>
        \"\"\"
      end
    end
    """)

    %{root: root, component: component}
  end

  test "inlines relative imports and keeps bare imports external", %{
    root: root,
    component: component
  } do
    File.cd!(root, fn -> Hooks.run([]) end)
    source = File.read!(component)

    [_, script] =
      Regex.run(
        ~r/    <%!-- colocated-hook widget.js#Widget --%>\n(.*)    <%!-- \/colocated-hook --%>\n/s,
        source
      )

    assert script =~ ~s(    <script :type={Phoenix.LiveView.ColocatedHook} name=".Widget">\n)
    assert script =~ ~s(\n      import { animate } from "motion";\n)
    assert script =~ "\n      function label(el) {\n"
    assert script =~ ~s(\n      export default Widget;\n    </script>\n)
    refute script =~ "./helper.js"
    refute script =~ "unused"
    refute script =~ "Other"
    assert [_] = Regex.scan(~r/^\s*export /m, script)
  end

  test "a second run changes nothing and --check passes", %{root: root, component: component} do
    File.cd!(root, fn -> Hooks.run([]) end)
    generated = File.read!(component)

    File.cd!(root, fn ->
      Hooks.run([])
      Hooks.run(["--check"])
    end)

    assert File.read!(component) == generated
  end

  test "--check lists a stale file without writing it", %{root: root, component: component} do
    File.cd!(root, fn -> Hooks.run([]) end)

    File.write!(Path.join(root, "packages/live_base/assets/js/helper.js"), """
    export function label(el) {
      return el.id;
    }
    """)

    stale = File.read!(component)

    error =
      assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run(["--check"]) end) end

    assert error.message =~ "packages/live_base/lib/widget.ex"
    assert File.read!(component) == stale
  end

  test "an unknown entry or export names the file and line", %{root: root, component: component} do
    File.write!(component, """
    ~H\"\"\"
    <%!-- colocated-hook missing.js#Widget --%>
    <%!-- /colocated-hook --%>
    <%!-- colocated-hook widget.js#Missing --%>
    <%!-- /colocated-hook --%>
    \"\"\"
    """)

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end

    assert error.message =~
             "packages/live_base/lib/widget.ex:2: packages/live_base/assets/js/missing.js does not exist"

    File.write!(component, String.replace(File.read!(component), "missing.js", "widget.js"))

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end
    assert error.message =~ "packages/live_base/lib/widget.ex:4: "
    assert error.message =~ "has no export named Missing"
  end

  test "output from node on stdout or stderr does not reach the reply", %{
    root: root,
    component: component
  } do
    fake_node(root, """
    echo "warning on stdout"
    echo "warning on stderr" >&2
    exec "#{System.find_executable("node")}" "$@"
    """)

    File.cd!(root, fn -> Hooks.run([]) end)
    assert File.read!(component) =~ "export default Widget;"
  end

  test "a reply that is not JSON or is short is an error", %{root: root} do
    fake_node(root, ~s(echo "diagnostic text"\nprintf 'not json' > "$2"\n))

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end
    assert error.message =~ "did not reply with 1 hook results"
    assert error.message =~ "diagnostic text"

    fake_node(root, ~s(printf '{"hooks":[]}' > "$2"\n))

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end
    assert error.message =~ "did not reply with 1 hook results"
  end

  test "a bundler that exits non-zero shows its output", %{root: root} do
    fake_node(root, ~s(echo "bundler crashed" >&2\nexit 3\n))

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end
    assert error.message =~ "the hook bundler exited with 3"
    assert error.message =~ "bundler crashed"
  end

  test "markers in a file with CRLF line endings are found and kept", %{
    root: root,
    component: component
  } do
    File.write!(component, String.replace(File.read!(component), "\n", "\r\n"))

    File.cd!(root, fn -> Hooks.run([]) end)
    source = File.read!(component)

    assert source =~ "export default Widget;\r\n"
    refute source =~ ~r/[^\r]\n/
    File.cd!(root, fn -> Hooks.run(["--check"]) end)
  end

  test "--check fails when there are no blocks", %{root: root, component: component} do
    File.write!(component, "defmodule Widget do\nend\n")

    error =
      assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run(["--check"]) end) end

    assert error.message =~ "no colocated hook blocks"
  end

  test "a bundle that EEx would read fails", %{root: root} do
    File.write!(Path.join(root, "packages/live_base/assets/js/helper.js"), """
    export function label() {
      return "<%= label %>";
    }
    """)

    error = assert_raise Mix.Error, fn -> File.cd!(root, fn -> Hooks.run([]) end) end
    assert error.message =~ "packages/live_base/lib/widget.ex:7: "
    assert error.message =~ "`<%`"
  end

  # Puts a `node` that runs `body` first on PATH for the rest of the test.
  defp fake_node(root, body) do
    bin = Path.join(root, "bin-#{System.unique_integer([:positive])}")
    File.mkdir_p!(bin)
    node = Path.join(bin, "node")
    File.write!(node, "#!/bin/sh\n" <> body)
    File.chmod!(node, 0o755)

    path = System.get_env("PATH")
    System.put_env("PATH", bin <> ":" <> path)
    on_exit(fn -> System.put_env("PATH", path) end)
  end
end

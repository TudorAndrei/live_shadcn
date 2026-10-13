defmodule Mix.Tasks.Ui.AddTest do
  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  test "--into names the module after the path, with a ui directory as UI", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      Mix.Tasks.Ui.Add.run(["button", "--into", "lib/web/components/ui"])

      assert File.read!("lib/web/components/ui/button.ex") =~
               "defmodule Web.Components.UI.Button do"
    end)
  end
end

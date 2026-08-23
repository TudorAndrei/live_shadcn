defmodule LiveShadcnTools.IdentityTest do
  use ExUnit.Case, async: true

  # A component is identified by its source and its name, never by its name
  # alone. Upstream has a `message` in the shadcn registry and a different
  # `message` in AI Elements, and every stage that looked one up by name alone
  # reported the first one's evidence as the second one's: the inventory marked
  # the AI Elements `message` verified on the strength of a browser run against
  # shadcn's.

  describe "a reference" do
    test "joins the source to the name" do
      assert LiveShadcnTools.ref("shadcn", "message") == "shadcn/message"
      assert LiveShadcnTools.ref("ai_elements", "message") == "ai_elements/message"
    end

    test "splits back into the pair it came from" do
      for source <- LiveShadcnTools.sources(), name <- ~w(message alert-dialog) do
        assert LiveShadcnTools.parse_ref(LiveShadcnTools.ref(source, name)) == {source, name}
      end
    end

    test "refuses a source nobody publishes" do
      assert_raise Mix.Error, ~r/not a component reference/, fn ->
        LiveShadcnTools.parse_ref("radix/message")
      end
    end
  end

  describe "the path a component owns" do
    test "two components of the same name never share a spec file" do
      refute LiveShadcnTools.spec_path("shadcn", "message") ==
               LiveShadcnTools.spec_path("ai_elements", "message")
    end

    test "two components of the same name never share a module file" do
      refute LiveShadcnTools.module_path("shadcn", "message") ==
               LiveShadcnTools.module_path("ai_elements", "message")
    end

    test "each package holds the modules it ships" do
      assert LiveShadcnTools.module_path("shadcn", "message") =~ "packages/live_shadcn/"
      assert LiveShadcnTools.module_path("ai_elements", "message") =~ "packages/live_ai_elements/"
    end
  end

  describe "a name typed on the command line" do
    test "resolves while it names one component" do
      assert LiveShadcnTools.resolve("accordion") == {"shadcn", "accordion"}
    end

    test "is refused, not guessed at, when it names two" do
      assert_raise Mix.Error, ~r/names 2 components/, fn ->
        LiveShadcnTools.resolve("message")
      end
    end

    test "is accepted in full when the bare name is ambiguous" do
      assert LiveShadcnTools.resolve("ai_elements/message") == {"ai_elements", "message"}
      assert LiveShadcnTools.resolve("shadcn/message") == {"shadcn", "message"}
    end
  end
end

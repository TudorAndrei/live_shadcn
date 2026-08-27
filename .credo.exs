# Static analysis, shared by every project in the repository.
#
# Each `mix.exs` points at this file, so a rule is written once. Five copies of
# a rule set is five chances for them to disagree, and the disagreement is
# always found by somebody whose commit fails in one project and passes in
# another.
#
# ── Upstream ports and machine records are not linted ──
#
# `packages/live_shadcn/priv/registry/`, the AI Elements components and the
# contracts have separate package, format, and contract checks. Broad Credo
# style rules do not define the upstream port API. `hk.pkl` carries the same
# exclusion list so a fixer cannot change a reviewed port without updating its
# contract digest.
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/", "mix.exs"],
        excluded: [
          ~r"/_build/",
          ~r"/deps/",
          ~r"/node_modules/",
          # Reviewed upstream ports. See above.
          ~r"/priv/registry/",
          ~r"/live_ai_elements/lib/live_ai_elements/components/"
        ]
      },
      # `ex_slop` registers its own recommended checks — the marks of code
      # nobody read back: a comment that restates the line under it, a blanket
      # `rescue`, a fold that should have been a `map`. It ports the
      # high-signal `credence` rules too, so one plugin covers both.
      plugins: [{ExSlop, []}],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        # `extra`, not `enabled`. `enabled` replaces credo's default set, which
        # silently left two checks running the first time this file was written.
        extra: [
          # Mix task filenames and Phoenix LiveView directories follow framework
          # conventions, so the check is pointed at code with a free choice.
          {CredoNaming.Check.Consistency.ModuleFilename,
           excluded_paths: [
             "mix.exs",
             "lib/mix/tasks",
             "test",
             "lib/storybook_web/controllers",
             "lib/storybook_web/live"
           ]},
          {CredoNaming.Check.Warning.AvoidSpecificTermsInModuleNames,
           terms: ["Manager", "Helper"]},

          # Tuned, not suppressed. A threshold that fires on each explicit
          # dispatch table becomes noise and hides new complex functions.
          {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 16},
          {Credo.Check.Refactor.Nesting, max_nesting: 3}
        ],
        disabled: [
          # `mix format` owns line length, and it is already a gate in CI and in
          # `hk.pkl`. Two tools with an opinion about one thing is one too many.
          {Credo.Check.Readability.MaxLineLength, []},

          # Reviewed component ports can contain one large HEEx sigil. Splitting
          # the markup only to satisfy a line count makes review harder.
          {Credo.Check.Refactor.LongQuoteBlocks, []},

          # The reviewed ports name each other in full —
          # `LiveShadcn.Icon.icon` — because `mix ui.add` rewrites the namespace
          # on the way into an application and an alias would hide the name it
          # has to rewrite. The examples that call them read the same way.
          {Credo.Check.Design.AliasUsage, []},

          # The check is right about an application and wrong about this
          # repository. `Application.app_dir/2` finds a file inside the app
          # asking for it; `tools` has tests that read what it wrote into
          # `packages/live_shadcn/priv/registry/`, which is a sibling project
          # and not this one's priv at all. There is no app to ask.
          {ExSlop.Check.Warning.PathExpandPriv, []}
        ]
      }
    }
  ]
}

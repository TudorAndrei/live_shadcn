# Changelog

## 0.1.0

First release.

- Headless Phoenix LiveView commands for disclosure, dialogs, menus, popovers,
  listboxes, tabs, and form controls.
- Hooks for placement, focus, modal accessibility, keyboard navigation, and
  enter and exit transitions.
- Specialist behavior for Calendar, Carousel, Combobox, Command, Menubar,
  Resizable, Scroller, Sidebar, Slider, Toast, and other controls.
- Message Scroller anchoring, history, streaming, and animation behavior.
- Hooks ship as LiveView colocated hooks. Applications register the `hooks`
  map from `phoenix-colocated/live_base`. Colocated hooks require `phoenix`
  1.8 or later.

The JavaScript package requires Floating UI, Embla Carousel, Embla Autoplay,
and Motion. Follow the [installation guide](README.md#installation), including
Phoenix's esbuild path setup.

# Changelog

## Unreleased

- `mix ui.add --into` names a `ui` directory `UI` in the module namespace, as
  the default destination does. `--into lib/web/components/ui` now gives
  `Web.Components.UI.Button`, not `Web.Components.Ui.Button`.

## 0.1.0

First release. Includes 61 reviewed shadcn component ports for Phoenix LiveView.

- Public component source lives in `priv/registry` and can be copied into an
  application with `mix ui.add`.
- `mix ui.sync` reports current, outdated, and locally edited copies. It updates
  only unedited files unless the user explicitly replaces a copy.
- The registry includes Calendar, Carousel, Chart, Command, Drawer, Input Group,
  Input OTP, Menubar, Message Scroller, Resizable, Sidebar, Slider, and Sonner.
- Upstream class and CVA facts stay in marked blocks. Structural and behavior
  changes require port review.
- Icons use `lucide_icons` by default and support an application renderer.
- Release acceptance requires current contract, snapshot, behavior,
  accessibility, semantic, and pixel evidence. It includes all official examples
  and the Data Table, Date Picker, and Typography documentation families.

Follow the [installation guide](README.md#installation) for JavaScript peers,
hooks, pinned CSS, and Tailwind sources. Copied parent components retain
package references for nested components until the application edits them.
Shared behavior and those nested components follow the package version.

Accessibility checks compare each port with its pinned upstream example.
Existing upstream findings remain visible in reports. New port findings fail
verification.

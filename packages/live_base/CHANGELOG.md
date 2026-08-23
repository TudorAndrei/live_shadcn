# Changelog

## 0.1.0

First release.

### The recipes

Seven behavior modules, each a set of `Phoenix.LiveView.JS` commands and the ids
they derive. None of them renders anything.

- `LiveBase.Disclosure` — a panel that opens and closes
- `LiveBase.Dialog` — something over the page that takes the focus with it
- `LiveBase.Popover` — something beside its trigger
- `LiveBase.Menu` — a list of things to choose from
- `LiveBase.Listbox` — a list that holds a value
- `LiveBase.Tabs` — panels of which exactly one shows
- `LiveBase.FormControl` — a control that holds a value, filled in from a
  `Phoenix.HTML.FormField`

### The hooks

Four, and each is there because no `JS` command reaches what it does:

- `LiveBase.Disclosure` — measures the height a class string interpolates, and
  holds the enter and exit attributes for the length of a transition
- `LiveBase.Overlay` — scroll lock, focus containment, and exit timing
- `LiveBase.Floating` — floating placement through `@floating-ui/dom`, and the
  side, alignment and CSS variables that follow from where a popup landed
- `LiveBase.Roving` — arrow keys, Home and End along a set of items

A hook decides *which* element, never *what happens to it*.

### Known limits

- `@floating-ui/dom` is a peer dependency: install it in your own assets.
- Typeahead — jumping to an option by typing its first letters — is not
  implemented yet. The `Roving` hook is where it will go.

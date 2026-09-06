export function scopeFromEnvironment(environment = process.env) {
  return {
    only: environment.PREVIEW_COMPONENT,
    onlyExample: environment.PREVIEW_EXAMPLE,
    selected: selected(environment.PREVIEW_COMPONENTS),
    selectedExamples: selected(environment.PREVIEW_EXAMPLES),
    onlySource: environment.PREVIEW_SOURCE,
  };
}

export function inScope(name, scope, source) {
  const [component, example] = name.split(".", 2);

  return (
    (!scope.only || component === scope.only) &&
    (!scope.onlyExample || example === scope.onlyExample) &&
    (scope.selected.size === 0 || scope.selected.has(component)) &&
    (scope.selectedExamples.size === 0 || scope.selectedExamples.has(example)) &&
    (!scope.onlySource || source(component) === scope.onlySource)
  );
}

export function hasScopeFilter(scope) {
  return (
    Boolean(scope.only) ||
    Boolean(scope.onlyExample) ||
    scope.selected.size > 0 ||
    scope.selectedExamples.size > 0 ||
    Boolean(scope.onlySource)
  );
}

export function noScopedPagesMessage(kind, scope) {
  if (hasScopeFilter(scope)) return `no ${kind} preview pages match this filter.`;
  return `no ${kind} preview pages are available. Refresh the Storybook snapshots.`;
}

function selected(value) {
  return new Set((value || "").split(",").filter(Boolean));
}

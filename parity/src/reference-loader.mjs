export async function loadReferenceExample(pathname, { officialComponents, officialExamples, examples }) {
  const [, , component, id] = pathname.split("/");
  const key = `${component}.${id}`;
  const loaders = officialComponents.has(component) ? officialExamples : examples;
  const load = Object.hasOwn(loaders, key) ? loaders[key] : undefined;
  return load ? await load() : undefined;
}

// Extracts the small set of TSX facts that a reviewed HEEx port can follow.
//
// The request is JSON with a `files` object. The response has exact class and
// CVA facts plus one structural fingerprint. Safe literal values do not affect
// the fingerprint. All other syntax does.

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { parseSync, visitorKeys } from "oxc-parser";

const requestPath = process.argv[2];

if (!requestPath) {
  process.stderr.write("usage: node priv/facts.mjs <request.json>\n");
  process.exit(2);
}

const request = JSON.parse(readFileSync(requestPath, "utf8"));
const output = {};

for (const path of Object.keys(request.files ?? {}).sort()) {
  output[path] = extract(path, request.files[path]);
}

process.stdout.write(JSON.stringify({ files: output }));

function extract(path, source) {
  const { program, errors } = parseSync(path, source);

  if (errors.length > 0) {
    process.stderr.write(
      JSON.stringify({
        error: "parse",
        path,
        diagnostics: errors.map((error) => {
          const label = error.labels?.[0];

          return {
            message: error.message,
            start: label ? Buffer.byteLength(source.slice(0, label.start), "utf8") : null,
            end: label ? Buffer.byteLength(source.slice(0, label.end), "utf8") : null,
          };
        }),
      }) + "\n",
    );
    process.exit(1);
  }

  const facts = {};
  const safeNodes = new WeakSet();
  const cvaNodes = new WeakSet();
  const classCounts = new Map();

  visit(program, null);

  const structure = normalize(program, safeNodes, cvaNodes);

  return {
    facts: Object.fromEntries(Object.entries(facts).sort(([a], [b]) => a.localeCompare(b))),
    fingerprint: createHash("sha256").update(stable(structure)).digest("hex"),
  };

  function visit(node, owner) {
    if (!node || typeof node !== "object") return;

    if (node.type === "FunctionDeclaration" && node.id?.name) owner = node.id.name;

    if (
      node.type === "VariableDeclarator" &&
      node.id?.type === "Identifier" &&
      isFunction(node.init)
    ) {
      owner = node.id.name;
    }

    if (node.type === "VariableDeclarator" && node.id?.type === "Identifier" && isCva(node.init)) {
      readCva(node.id.name, node.init);
    }

    if (node.type === "JSXAttribute" && jsxName(node.name) === "className") {
      readClass(node.value?.expression ?? node.value, owner ?? "anonymous");
    }

    for (const key of visitorKeys[node.type] ?? []) {
      const child = node[key];

      if (Array.isArray(child)) child.forEach((item) => visit(item, owner));
      else visit(child, owner);
    }
  }

  function readClass(node, owner) {
    if (!node) return;

    if (stringNode(node)) {
      const index = classCounts.get(owner) ?? 0;
      classCounts.set(owner, index + 1);
      safeNodes.add(node);
      facts[`jsx/${owner}/class/${index}`] = node.value;
      return;
    }

    if (node.type === "CallExpression" && ["cn", "clsx"].includes(calleeName(node.callee))) {
      node.arguments.forEach((argument) => readClassOutput(argument));
    }
  }

  function readClassOutput(node) {
    if (!node) return;

    if (stringNode(node)) {
      const owner = enclosingOwner(node) ?? "anonymous";
      const index = classCounts.get(owner) ?? 0;
      classCounts.set(owner, index + 1);
      safeNodes.add(node);
      facts[`jsx/${owner}/class/${index}`] = node.value;
      return;
    }

    switch (node.type) {
      case "ConditionalExpression":
        readClassOutput(node.consequent);
        readClassOutput(node.alternate);
        break;
      case "LogicalExpression":
        readClassOutput(node.right);
        break;
      case "ArrayExpression":
        node.elements.forEach(readClassOutput);
        break;
      case "CallExpression":
        if (["cn", "clsx"].includes(calleeName(node.callee))) {
          node.arguments.forEach(readClassOutput);
        }
        break;
    }
  }

  // The generic visitor does not expose parents. Find the owner by source
  // order from the function ranges. This path runs only for literals nested in
  // a class expression.
  function enclosingOwner(node) {
    let answer = null;

    find(program, null);
    return answer;

    function find(current, owner) {
      if (!current || typeof current !== "object") return;
      if (current.type === "FunctionDeclaration" && current.id?.name) owner = current.id.name;

      if (
        current.type === "VariableDeclarator" &&
        current.id?.type === "Identifier" &&
        isFunction(current.init)
      ) {
        owner = current.id.name;
      }

      if (current === node) answer = owner;
      if (answer) return;

      for (const key of visitorKeys[current.type] ?? []) {
        const child = current[key];

        if (Array.isArray(child)) child.forEach((item) => find(item, owner));
        else find(child, owner);
      }
    }
  }

  function readCva(binding, call) {
    cvaNodes.add(call);
    const [base, options] = call.arguments;

    if (stringNode(base)) facts[`cva/${binding}/base`] = base.value;

    const variants = propertyValue(options, "variants");

    for (const group of objectProperties(variants)) {
      const groupName = propertyName(group);

      for (const variant of objectProperties(group.value)) {
        if (stringNode(variant.value)) {
          facts[`cva/${binding}/variant/${groupName}/${propertyName(variant)}`] =
            variant.value.value;
        }
      }
    }

    const defaults = propertyValue(options, "defaultVariants");

    for (const entry of objectProperties(defaults)) {
      if (stringNode(entry.value)) {
        facts[`cva/${binding}/default/${propertyName(entry)}`] = entry.value.value;
      }
    }
  }
}

function normalize(value, safeNodes, cvaNodes) {
  if (value === null || typeof value !== "object") return value;
  if (cvaNodes.has(value)) return { type: "CallExpression", callee: "cva", facts: true };

  if (safeNodes.has(value)) {
    return { type: value.type, value: "__UPSTREAM_FACT__" };
  }

  if (Array.isArray(value)) return value.map((item) => normalize(item, safeNodes, cvaNodes));

  const ignored = new Set(["start", "end", "raw", "loc", "comments", "leadingComments"]);
  const result = {};

  for (const key of Object.keys(value).sort()) {
    if (!ignored.has(key)) result[key] = normalize(value[key], safeNodes, cvaNodes);
  }

  return result;
}

function stable(value) {
  return JSON.stringify(value);
}

function isFunction(node) {
  return ["ArrowFunctionExpression", "FunctionExpression"].includes(node?.type);
}

function isCva(node) {
  return node?.type === "CallExpression" && calleeName(node.callee) === "cva";
}

function calleeName(node) {
  return node?.type === "Identifier" ? node.name : null;
}

function stringNode(node) {
  return node?.type === "Literal" && typeof node.value === "string";
}

function jsxName(node) {
  return node?.type === "JSXIdentifier" ? node.name : null;
}

function objectProperties(node) {
  return node?.type === "ObjectExpression" ? node.properties.filter((item) => item.type === "Property") : [];
}

function propertyName(property) {
  if (property?.key?.type === "Identifier") return property.key.name;
  if (stringNode(property?.key)) return property.key.value;
  return null;
}

function propertyValue(object, name) {
  return objectProperties(object).find((item) => propertyName(item) === name)?.value;
}

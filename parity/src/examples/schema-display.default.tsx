import {
  SchemaDisplay,
  SchemaDisplayDescription,
  SchemaDisplayHeader,
  SchemaDisplayMethod,
  SchemaDisplayPath,
} from "@upstream/ai_elements/schema-display";

// Ported from `StorybookWeb.Examples.schema_display_default/1`.
//
// `<SchemaDisplay>` puts the endpoint in a context and each part reads it back;
// here each part is given what it draws, and the wrapper is present only so the
// React side has a context to read.
//
// The path is `dangerouslySetInnerHTML` upstream — a string of markup, put in
// where markup goes. HEEx has no such door, so the generated component reads
// that attribute as what it means, the element's children.
export default function SchemaDisplayDefault() {
  return (
    <div className="max-w-md space-y-2">
      <SchemaDisplay
        description="One component, by name."
        method="GET"
        path="/components/{name}"
      >
        <SchemaDisplayHeader>
          <SchemaDisplayMethod />
          <SchemaDisplayPath />
        </SchemaDisplayHeader>
        <SchemaDisplayDescription />
      </SchemaDisplay>
    </div>
  );
}

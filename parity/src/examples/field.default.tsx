import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
} from "@upstream/shadcn/ui/field";
import { Input } from "@upstream/shadcn/ui/input";

// Ported from `StorybookWeb.Examples.field_default/1`.
export default function FieldDefault() {
  return (
    <Field className="max-w-sm">
      <FieldLabel htmlFor="registry">Registry</FieldLabel>
      <FieldContent>
        <Input id="registry" name="registry" value="shadcn" />
        <FieldDescription>Which upstream registry to read.</FieldDescription>
      </FieldContent>
    </Field>
  );
}

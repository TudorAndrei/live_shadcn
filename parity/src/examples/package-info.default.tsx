import {
  PackageInfo,
  PackageInfoChangeType,
  PackageInfoContent,
  PackageInfoDescription,
  PackageInfoHeader,
  PackageInfoName,
} from "@upstream/ai_elements/package-info";

// Ported from `StorybookWeb.Examples.package_info_default/1`.
//
// `name` and `changeType` are props of the root upstream, read back out of a
// context by the parts that draw them. A HEEx component has no context, so each
// part takes what it draws — and the example gives both sides the same words.
export default function PackageInfoDefault() {
  return (
    <PackageInfo className="max-w-sm" name="phoenix_live_view" changeType="minor">
      <PackageInfoHeader>
        <PackageInfoName>phoenix_live_view</PackageInfoName>
        <PackageInfoChangeType>minor</PackageInfoChangeType>
      </PackageInfoHeader>
      <PackageInfoContent>
        <PackageInfoDescription>
          The framework every component is built on.
        </PackageInfoDescription>
      </PackageInfoContent>
    </PackageInfo>
  );
}

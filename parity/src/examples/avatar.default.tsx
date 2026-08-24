import { Avatar, AvatarFallback, AvatarGroup, AvatarGroupCount } from "@upstream/shadcn/ui/avatar";

// Ported from `StorybookWeb.Examples.avatar_default/1`.
export default function AvatarDefault() {
  return (
    <AvatarGroup>
      <Avatar>
        <AvatarFallback>BU</AvatarFallback>
      </Avatar>
      <Avatar>
        <AvatarFallback>SC</AvatarFallback>
      </Avatar>
      <AvatarGroupCount>+3</AvatarGroupCount>
    </AvatarGroup>
  );
}

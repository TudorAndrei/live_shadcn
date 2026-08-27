import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarSeparator,
  SidebarTrigger,
} from "@upstream/shadcn/ui/sidebar";
import { Icon } from "../shim/lucide";

const PIPELINE = [
  { label: "Fetch", name: "cloud-download" },
  { label: "Spec", name: "file-json" },
  { label: "Generate", name: "wand-sparkles" },
  { label: "Verify", name: "circle-check" },
];

const REGISTRY = [
  { label: "Components", name: "boxes" },
  { label: "Recipes", name: "book-open" },
  { label: "Upstream", name: "git-branch" },
];

// Ported from `StorybookWeb.Examples.sidebar_default/1`.
//
// `SidebarInset` is left out on both sides. It is a `<main>`, and the page
// already has one around every example.
//
// `tooltip` is left out on both sides too, and for a reason worth writing
// down. Upstream wraps the button in a `<Tooltip>` when it is given, which
// needs a `TooltipProvider` above it; the reviewed port declares the
// attribute and renders nothing for it. So an example that passed `tooltip`
// would be comparing a tooltip against nothing, and the port would be hiding
// the difference rather than showing it.
export default function SidebarDefault() {
  return (
    <SidebarProvider className="min-h-96">
      <Sidebar collapsible="icon">
        <SidebarHeader>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton size="lg">
                <Icon name="component" className="size-4" />
                <span className="font-semibold">live_shadcn</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarHeader>

        <SidebarContent>
          <SidebarGroup>
            <SidebarGroupLabel>Pipeline</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {PIPELINE.map(({ label, name }) => (
                  <SidebarMenuItem key={label}>
                    <SidebarMenuButton isActive={label === "Spec"}>
                      <Icon name={name} className="size-4" />
                      <span>{label}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>

          <SidebarSeparator />

          <SidebarGroup>
            <SidebarGroupLabel>Registry</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {REGISTRY.map(({ label, name }) => (
                  <SidebarMenuItem key={label}>
                    <SidebarMenuButton>
                      <Icon name={name} className="size-4" />
                      <span>{label}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>

        <SidebarFooter>
          <SidebarMenu>
            <SidebarMenuItem>
              <SidebarMenuButton>
                <Icon name="circle-user" className="size-4" />
                <span>Signed in</span>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarFooter>

        <SidebarRail />
      </Sidebar>

      <div className="flex flex-1 items-start gap-2 p-3">
        <SidebarTrigger />
        <p className="text-sm text-muted-foreground">
          The trigger and the rail both flip one attribute, and every class string reads it. No
          round trip.
        </p>
      </div>
    </SidebarProvider>
  );
}

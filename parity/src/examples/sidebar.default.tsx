import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuSubButton,
  SidebarProvider,
  SidebarRail,
  SidebarTrigger,
} from "@upstream/shadcn/ui/sidebar";

// Ported from `StorybookWeb.Examples.sidebar_default/1`.
export default function SidebarDefault() {
  return (
    <SidebarProvider className="min-h-64">
      <Sidebar collapsible="icon">
        <SidebarHeader>
          <SidebarGroupLabel>Pipeline</SidebarGroupLabel>
          <SidebarTrigger />
        </SidebarHeader>
        <SidebarContent>
          <SidebarGroup>
            <SidebarGroupContent>
              <SidebarMenu>
                {["Fetch", "Spec", "Generate", "Verify"].map((stage) => (
                  <SidebarMenuItem key={stage}>
                    <SidebarMenuSubButton href="#">{stage}</SidebarMenuSubButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        </SidebarContent>
        <SidebarRail />
      </Sidebar>
    </SidebarProvider>
  );
}

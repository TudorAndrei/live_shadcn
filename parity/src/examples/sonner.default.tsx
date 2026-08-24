import { ThemeProvider } from "next-themes";
import { Toaster } from "@upstream/shadcn/ui/sonner";

// Ported from `StorybookWeb.Examples.sonner_default/1`.
export default function SonnerDefault() {
  return (
    <ThemeProvider defaultTheme="light">
      <Toaster />
    </ThemeProvider>
  );
}

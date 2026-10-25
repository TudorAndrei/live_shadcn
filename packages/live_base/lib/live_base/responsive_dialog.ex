defmodule LiveBase.ResponsiveDialog do
  @moduledoc """
  Shows the desktop or the mobile branch of a responsive dialog from the same
  media query as upstream. The root marks its children `data-lb-desktop` and
  `data-lb-mobile`.
  """

  use Phoenix.Component

  @doc "The client hook name the responsive root declares in `phx-hook`."
  def hook, do: "LiveBase.ResponsiveDialog.ResponsiveDialog"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook responsive_dialog.js#ResponsiveDialog --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ResponsiveDialog">
      const ResponsiveDialog = {
        mounted() {
          this.query = window.matchMedia("(min-width: 768px)");
          this.onChange = () => this.sync();
          this.query.addEventListener("change", this.onChange);
          this.sync();
        },
        updated() {
          this.sync();
        },
        destroyed() {
          this.query?.removeEventListener("change", this.onChange);
        },
        sync() {
          const desktop = this.el.querySelector(":scope > [data-lb-desktop]");
          const mobile = this.el.querySelector(":scope > [data-lb-mobile]");
          if (desktop) desktop.hidden = !this.query.matches;
          if (mobile) mobile.hidden = this.query.matches;
        }
      };
      export default ResponsiveDialog;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end

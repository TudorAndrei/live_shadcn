export const ChartTooltip = {
  mounted() {
    this.tooltip = this.el.querySelector("[data-chart-tooltip]");
    this.content = this.tooltip?.querySelector(".cn-chart-tooltip");
    this.cursor = this.el.querySelector("[data-chart-cursor]");

    this.showTooltip = (event) => {
      const bar = event.target.closest("[data-chart-index]");
      if (!bar || !this.tooltip || !this.content) return;

      const index = bar.dataset.chartIndex;
      const values = new Map(
        [...this.el.querySelectorAll(`[data-chart-index='${index}']`)].map((item) => [
          item.dataset.chartSeries,
          item.dataset.chartValue,
        ]),
      );

      this.content.children[0].textContent = bar.dataset.chartMonth;
      const rows = this.content.children[1].children;
      rows[0].querySelector(".font-mono").textContent = Number(values.get("desktop")).toLocaleString();
      rows[1].querySelector(".font-mono").textContent = Number(values.get("mobile")).toLocaleString();

      this.tooltip.style.visibility = "visible";

      const chart = this.el.getBoundingClientRect();
      const tooltip = this.tooltip.getBoundingClientRect();
      const categoryWidth = 710 / 6;
      const categoryIndex = this.el.dataset.chartRtl === "true" ? 5 - Number(index) : Number(index);
      const categoryX = 5 + categoryWidth * categoryIndex;
      let x = categoryX + categoryWidth / 2 + 10;
      let y = Math.floor(event.clientY - chart.top) + 10;

      if (x + tooltip.width > chart.width) {
        x = categoryX + categoryWidth / 2 - tooltip.width - 10;
      }
      y = Math.max(0, Math.min(y, chart.height - tooltip.height));

      this.tooltip.style.transform = `translate(${x}px, ${y}px)`;

      if (this.cursor) {
        const cursorWidth = 118.3333;
        const cursorHeight = Number(this.cursor.dataset.chartCursorHeight);
        this.cursor.setAttribute(
          "d",
          `M ${categoryX},5.5 h ${cursorWidth} v ${cursorHeight} h -${cursorWidth} Z`,
        );
        this.cursor.style.visibility = "visible";
      }
    };

    this.hideTooltip = () => {
      if (this.tooltip) this.tooltip.style.visibility = "hidden";
      if (this.cursor) this.cursor.style.visibility = "hidden";
    };

    this.el.addEventListener("pointermove", this.showTooltip);
    this.el.addEventListener("pointerleave", this.hideTooltip);
    this.el.dataset.chartReady = "true";
  },

  destroyed() {
    this.el.removeEventListener("pointermove", this.showTooltip);
    this.el.removeEventListener("pointerleave", this.hideTooltip);
  },
};

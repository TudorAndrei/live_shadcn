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

// The daily demo has one active series. Read its current server-rendered bars
// on each event so a connected series change cannot retain old values.
export const ChartDemoTooltip = {
  mounted() {
    this.showTooltip = (event) => {
      const bar = event.target.closest("[data-chart-date]");
      const tooltip = this.el.querySelector("[data-chart-tooltip]");
      if (!bar || !tooltip) return;
      const content = tooltip.querySelector(".cn-chart-tooltip");
      content.firstElementChild.textContent = new Date(`${bar.dataset.chartDate}T00:00:00Z`)
        .toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric", timeZone: "UTC" });
      content.querySelector(".font-mono").textContent = Number(bar.dataset.chartValue).toLocaleString("en-US");
      tooltip.style.visibility = "visible";

      const chart = this.el.getBoundingClientRect();
      const box = tooltip.getBoundingClientRect();
      const categoryWidth = 646 / 30;
      const categoryX = 12 + Number(bar.dataset.chartIndex) * categoryWidth;
      const matrix = this.el.querySelector("svg").getScreenCTM();
      const plotStart = new DOMPoint(12, 0).matrixTransform(matrix);
      const plotEnd = new DOMPoint(658, 220).matrixTransform(matrix);
      const anchor = new DOMPoint(categoryX + categoryWidth / 2, 0).matrixTransform(matrix);
      const x = anchor.x - chart.left;
      const y = Math.round(event.clientY - chart.top);
      const left = Math.max(plotStart.x - chart.left,
        x + 10 + box.width > plotEnd.x - chart.left ? x - box.width - 10 : x + 10);
      const top = Math.max(plotStart.y - chart.top,
        y + 10 + box.height > plotEnd.y - chart.top ? y - box.height - 10 : y + 10);
      tooltip.style.transform = `translate(${left}px, ${top}px)`;
      const cursor = this.el.querySelector("[data-chart-cursor]");
      cursor.setAttribute("d", `M ${categoryX},0.5 h 21.5333 v 219 h -21.5333 Z`);
      cursor.style.visibility = "visible";
    };
    this.hideTooltip = () => {
      this.el.querySelector("[data-chart-tooltip]").style.visibility = "hidden";
      this.el.querySelector("[data-chart-cursor]").style.visibility = "hidden";
    };
    this.el.addEventListener("pointermove", this.showTooltip);
    this.el.addEventListener("pointerleave", this.hideTooltip);
    this.el.dataset.chartReady = "true";
  },

  updated() {
    this.hideTooltip();
  },

  destroyed() {
    this.el.removeEventListener("pointermove", this.showTooltip);
    this.el.removeEventListener("pointerleave", this.hideTooltip);
  },
};

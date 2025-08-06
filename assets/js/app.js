// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"
// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Chart from "chart.js/auto";
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
// Chart.js Hook for Balance Charts
const BalanceChart = {
  mounted() {
    this.chart = null;
    this.updateChart();
  },

  updated() {
    this.updateChart();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },

  updateChart() {
    const chartData = JSON.parse(this.el.dataset.chartData);

    if (this.chart) {
      this.chart.destroy();
    }

    const ctx = document.createElement("canvas");
    this.el.innerHTML = "";
    this.el.appendChild(ctx);

    this.chart = new Chart(ctx, {
      type: "line",
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: false,
          },
          legend: {
            display: false, // We'll use custom legend below
          },
          tooltip: {
            mode: "index",
            intersect: false,
            callbacks: {
              title: function (context) {
                return `Day ${context[0].label}`;
              },
              label: function (context) {
                const value = context.parsed.y;
                if (value !== null) {
                  // Use the custom month property we added to the dataset
                  const monthName =
                    context.dataset.month ||
                    `Month ${context.datasetIndex + 1}`;
                  return `${monthName}: €${value}`;
                }
                return null;
              },
            },
          },
        },
        scales: {
          x: {
            title: {
              display: true,
              text: "Day of Month",
            },
            grid: {
              display: true,
              color: "rgba(0, 0, 0, 0.1)",
            },
          },
          y: {
            title: {
              display: true,
              text: "Balance (EUR)",
            },
            grid: {
              display: true,
              color: "rgba(0, 0, 0, 0.1)",
            },
            ticks: {
              callback: function (value) {
                return "€" + value;
              },
            },
          },
        },
        interaction: {
          mode: "nearest",
          axis: "x",
          intersect: false,
        },
        elements: {
          point: {
            radius: 2,
            hoverRadius: 6,
          },
          line: {
            tension: 0.4,
          },
        },
      },
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
  },
  hooks: {
    BalanceChart,
  },
});
// Show progress bar on live navigation and form submits
topbar.config({
  barColors: {
    0: "#29d",
  },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
// connect if there are any LiveViews on the page
liveSocket.connect();
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Allows to execute JS commands from the server
window.addEventListener("phx:js-exec", ({ detail }) => {
  document.querySelectorAll(detail.to).forEach((el) => {
    liveSocket.execJS(el, el.getAttribute(detail.attr));
  });
});

// Update money amount display when payment amount changes
document.addEventListener("input", (event) => {
  if (event.target.id === "payment-amount-input") {
    const amountInCents = parseInt(event.target.value) || 0;
    const amountInCurrency = (amountInCents / 100).toFixed(2);
    const displayElement = document.getElementById("euro-amount-display");
    if (displayElement) {
      displayElement.textContent = `Amount: EUR ${amountInCurrency}`;
    }
  }
});

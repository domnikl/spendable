defmodule SpendableWeb.DashboardLive.BalanceChartComponent do
  use SpendableWeb, :live_component

  alias Spendable.{Accounts, Users}

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_chart_data()

    {:ok, socket}
  end

  @impl true
  def handle_event("change_account", %{"account_id" => account_id}, socket) do
    account_id = String.to_integer(account_id)

    # Update user preference
    Users.update_user_preferences(socket.assigns.current_user, %{
      preferred_chart_account_id: account_id
    })

    socket =
      socket
      |> assign(:selected_account_id, account_id)
      |> assign_chart_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_month", %{"month" => month}, socket) do
    visible_months = socket.assigns.visible_months

    new_visible_months =
      if month in visible_months do
        List.delete(visible_months, month)
      else
        [month | visible_months]
      end

    socket = assign(socket, :visible_months, new_visible_months)

    {:noreply, socket}
  end

  defp assign_chart_data(socket) do
    # Accounts are now passed as a regular list
    accounts = socket.assigns.accounts

    current_user = socket.assigns.current_user

    # Get selected account (from user preference or first account)
    selected_account_id =
      socket.assigns[:selected_account_id] ||
        current_user.preferred_chart_account_id ||
        if Enum.empty?(accounts), do: nil, else: hd(accounts).id

    if selected_account_id do
      chart_data = Accounts.get_balance_chart_data(selected_account_id)
      all_months = Accounts.get_chart_months()

      # Default to showing last 3 months
      default_visible_months = Enum.take(all_months, -3)

      socket
      |> assign(:selected_account_id, selected_account_id)
      |> assign(:chart_data, chart_data)
      |> assign(:all_months, all_months)
      |> assign_new(:visible_months, fn -> default_visible_months end)
    else
      socket
      |> assign(:selected_account_id, nil)
      |> assign(:chart_data, %{})
      |> assign(:all_months, [])
      |> assign(:visible_months, [])
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div class="px-6 py-5 border-b border-gray-200">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-xl font-semibold text-gray-900 flex items-center">
              <div class="w-2 h-2 bg-purple-500 rounded-full mr-3"></div>
              Account Balance History
            </h2>
            <p class="mt-1 text-sm text-gray-600">Daily balance trends over time</p>
          </div>
          
    <!-- Account Selector -->
          <%= if not Enum.empty?(@accounts) do %>
            <div class="flex items-center space-x-3">
              <label for="account-select" class="text-sm font-medium text-gray-700">Account:</label>
              <form phx-change="change_account" phx-target={@myself}>
                <select
                  id="account-select"
                  name="account_id"
                  class="rounded-md border-gray-300 text-sm focus:border-purple-500 focus:ring-purple-500"
                >
                  <%= for account <- @accounts do %>
                    <option value={account.id} selected={account.id == @selected_account_id}>
                      {account.product} - {account.owner_name}
                    </option>
                  <% end %>
                </select>
              </form>
            </div>
          <% end %>
        </div>
      </div>

      <div class="p-6">
        <%= if Enum.empty?(@accounts) do %>
          <div class="text-center py-8 text-gray-500">
            <p>No accounts available for chart display</p>
          </div>
        <% else %>
          <!-- Month Toggles -->
          <div class="mb-6">
            <h3 class="text-sm font-medium text-gray-700 mb-3">Months to Display:</h3>
            <div class="flex flex-wrap gap-2">
              <%= for month <- @all_months do %>
                <button
                  phx-click="toggle_month"
                  phx-value-month={month}
                  phx-target={@myself}
                  class={[
                    "px-3 py-1 rounded-full text-xs font-medium transition-colors",
                    if month in @visible_months do
                      "bg-purple-100 text-purple-800 border border-purple-200"
                    else
                      "bg-gray-100 text-gray-600 border border-gray-200 hover:bg-gray-200"
                    end
                  ]}
                >
                  {format_month_label(month)}
                </button>
              <% end %>
            </div>
          </div>
          
    <!-- Chart Container -->
          <div class="relative">
            <div
              id="balance-chart"
              phx-hook="BalanceChart"
              data-chart-data={Jason.encode!(prepare_chart_data(@chart_data, @visible_months))}
              class="w-full h-80"
            >
              <!-- Fallback for when JS is not loaded -->
              <div class="flex items-center justify-center h-80 bg-gray-50 rounded-lg">
                <p class="text-gray-500">Loading chart...</p>
              </div>
            </div>
          </div>
          
    <!-- Legend -->
          <div class="mt-4 flex flex-wrap gap-4">
            <%= for {month, index} <- Enum.with_index(@visible_months) do %>
              <div class="flex items-center">
                <div class={["w-3 h-3 rounded mr-2", get_month_color_class(index)]}></div>
                <span class="text-sm text-gray-600">{format_month_label(month)}</span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp prepare_chart_data(chart_data, visible_months) do
    # Prepare data for Chart.js
    datasets =
      visible_months
      |> Enum.with_index()
      |> Enum.map(fn {month, index} ->
        monthly_data = Map.get(chart_data, month, %{})

        # Generate data points for all days 1-31
        data_points =
          1..31
          |> Enum.map(fn day ->
            Map.get(monthly_data, day, nil)
          end)

        %{
          data: data_points,
          borderColor: get_month_color(index),
          backgroundColor: get_month_color(index, 0.1),
          tension: 0.4,
          pointRadius: 2,
          pointHoverRadius: 4,
          # Connect points even when there are null values
          spanGaps: true,
          # Add month info for tooltip but don't use 'label' to avoid legend
          month: format_month_label(month)
        }
      end)

    %{
      labels: Enum.to_list(1..31),
      datasets: datasets
    }
  end

  defp format_month_label(month_string) do
    [year, month] = String.split(month_string, "-")

    month_names = %{
      "01" => "Jan",
      "02" => "Feb",
      "03" => "Mar",
      "04" => "Apr",
      "05" => "May",
      "06" => "Jun",
      "07" => "Jul",
      "08" => "Aug",
      "09" => "Sep",
      "10" => "Oct",
      "11" => "Nov",
      "12" => "Dec"
    }

    month_name = Map.get(month_names, month, month)
    "#{month_name} #{year}"
  end

  defp get_month_color(index, alpha \\ 1.0) do
    colors = [
      # Purple
      "rgba(147, 51, 234, #{alpha})",
      # Blue
      "rgba(59, 130, 246, #{alpha})",
      # Green
      "rgba(16, 185, 129, #{alpha})",
      # Amber
      "rgba(245, 158, 11, #{alpha})",
      # Red
      "rgba(239, 68, 68, #{alpha})",
      # Violet
      "rgba(139, 92, 246, #{alpha})",
      # Cyan
      "rgba(6, 182, 212, #{alpha})",
      # Emerald
      "rgba(34, 197, 94, #{alpha})",
      # Orange
      "rgba(251, 146, 60, #{alpha})",
      # Pink
      "rgba(236, 72, 153, #{alpha})",
      # Indigo
      "rgba(99, 102, 241, #{alpha})",
      # Lime
      "rgba(132, 204, 22, #{alpha})"
    ]

    Enum.at(colors, rem(index, length(colors)))
  end

  defp get_month_color_class(index) do
    classes = [
      "bg-purple-500",
      "bg-blue-500",
      "bg-green-500",
      "bg-amber-500",
      "bg-red-500",
      "bg-violet-500",
      "bg-cyan-500",
      "bg-emerald-500",
      "bg-orange-500",
      "bg-pink-500",
      "bg-indigo-500",
      "bg-lime-500"
    ]

    Enum.at(classes, rem(index, length(classes)))
  end
end

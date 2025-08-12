defmodule SpendableWeb.BudgetsLive.Index do
  use SpendableWeb, :live_view

  import SaladUI.Checkbox

  alias Spendable.Budgets
  alias Spendable.Budgets.Budget
  alias Spendable.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    accounts = Accounts.list_accounts(user)

    # Always start by showing all budgets on initial load
    budgets = Budgets.list_budgets(user)

    socket =
      socket
      |> stream(:budgets, budgets, dom_id: &"budget-#{&1.id}")
      |> assign(:page_title, "Budgets")
      |> assign(:accounts, accounts)
      |> assign(:selected_account_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Budget")
    |> assign(:budget, Budgets.get_budget!(socket.assigns.current_user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Budget")
    |> assign(:budget, %Budget{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Budgets")
    |> assign(:budget, nil)
  end

  @impl true
  def handle_info({SpendableWeb.BudgetsLive.FormComponent, {:saved, budget}}, socket) do
    # For new budgets, insert at the beginning
    {:noreply, stream_insert(socket, :budgets, budget, at: 0)}
  end

  @impl true
  def handle_info(
        {SpendableWeb.BudgetsLive.FormComponent, {:updated, old_budget, new_budget}},
        socket
      ) do
    # Remove the old budget (which is now inactive) and add the new one
    socket = stream_delete(socket, :budgets, old_budget)
    {:noreply, stream_insert(socket, :budgets, new_budget, at: 0)}
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>
      Budgets
      <:actions>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <label for="account-filter" class="text-sm font-medium text-gray-700">Account:</label>
            <form phx-change="filter_by_account">
              <select
                id="account-filter"
                name="account_id"
                value={@selected_account_id}
                class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              >
                <option value="">All Accounts</option>
                <%= for account <- @accounts do %>
                  <option value={account.id}>
                    {account.product} - {account.owner_name}
                  </option>
                <% end %>
              </select>
            </form>
          </div>
          <.link patch={~p"/budgets/new"}>
            <.button>New Budget</.button>
          </.link>
        </div>
      </:actions>
    </.header>

    <.table id="budgets-table" rows={@streams.budgets}>
      <:col :let={{dom_id, budget}} label="Name" class="">
        <span id={dom_id <> "-name"}>
          <%= if budget.parent do %>
            <.link patch={~p"/budgets/#{budget.parent.id}/edit"}>{budget.parent.name}</.link>
            <span class="text-gray-400"> → </span>
          <% end %>

          <.link patch={~p"/budgets/#{budget.id}/edit"} class="font-bold">{budget.name}</.link>
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Amount" class="hidden sm:table-cell">
        <span id={dom_id <> "-amount"}>
          <.money_amount amount={budget.amount} currency={budget.account.currency} />
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Used" class="hidden md:table-cell">
        <span id={dom_id <> "-used"}>
          <.money_amount amount={budget.total_used} currency={budget.account.currency} />
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Status" class="hidden lg:table-cell">
        <span id={dom_id <> "-status"}>
          <%= if budget.amount < 0 and budget.percentage_used do %>
            <div class="flex items-center space-x-2">
              <span class="text-sm">
                {Float.round(budget.percentage_used, 1)}%
              </span>
              <%= if budget.percentage_used > 100 do %>
                <span class="text-red-500">🔴</span>
              <% else %>
                <%= if budget.percentage_used > 80 do %>
                  <span class="text-yellow-500">🟡</span>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Account" class="hidden md:table-cell">
        <span id={dom_id <> "-account"}>{budget.account.product} {budget.account.owner_name}</span>
      </:col>

      <:col :let={{dom_id, budget}} label="Due Date" class="hidden lg:table-cell">
        <span id={dom_id <> "-due-date"}>
          {Calendar.strftime(budget.due_date, "%Y-%m-%d")}
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Interval" class="hidden xl:table-cell">
        <span id={dom_id <> "-interval"} class="capitalize">
          {String.replace(to_string(budget.interval), "_", " ")}
        </span>
      </:col>

      <:col :let={{dom_id, budget}} label="Active?">
        <div className="flex items-center space-x-2">
          <.checkbox
            id={dom_id <> "-checked"}
            value={budget.active}
            phx-click="toggle_budget_active"
            phx-value-budget_id={budget.id}
            phx-value-active={budget.active}
          />
          <.label for="checked"></.label>
        </div>
      </:col>

      <:col :let={{dom_id, budget}} label="Actions">
        <div id={dom_id <> "-actions"}>
          <.link patch={~p"/budgets/#{budget.id}/edit"} class="">Edit</.link>
        </div>
      </:col>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="budget-modal"
      show
      on_cancel={JS.patch(~p"/budgets")}
    >
      <.live_component
        module={SpendableWeb.BudgetsLive.FormComponent}
        id={@budget.id || @budget}
        title={@page_title}
        action={@live_action}
        current_user={@current_user}
        budget={@budget}
        patch={~p"/budgets"}
      />
    </.modal>
    """
  end

  defp toggle_budget_active(socket, budget_id, active) do
    budget = Spendable.Budgets.get_budget!(socket.assigns.current_user, budget_id)

    case Spendable.Budgets.set_active_budget(budget, active) do
      {:ok, _} ->
        # Refresh budgets with current account filter
        budgets =
          Budgets.list_budgets(
            socket.assigns.current_user,
            socket.assigns.selected_account_id
          )

        {:noreply,
         socket
         |> stream(:budgets, budgets, reset: true, dom_id: &"budget-#{&1.id}")
         |> put_flash(:info, "Budget updated.")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "toggle_budget_active",
        %{"budget_id" => budget_id, "value" => "true"},
        socket
      ) do
    socket |> toggle_budget_active(budget_id, true)
  end

  @impl true
  def handle_event("toggle_budget_active", %{"budget_id" => budget_id}, socket) do
    socket |> toggle_budget_active(budget_id, false)
  end

  @impl true
  def handle_event("filter_by_account", %{"account_id" => ""}, socket) do
    # Show all active budgets when "All Accounts" is selected
    budgets = Budgets.list_budgets(socket.assigns.current_user)

    socket =
      socket
      |> assign(:selected_account_id, nil)
      |> stream(:budgets, budgets, reset: true, dom_id: &"budget-#{&1.id}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_by_account", %{"account_id" => account_id}, socket) do
    account_id = String.to_integer(account_id)
    budgets = Budgets.list_budgets(socket.assigns.current_user, account_id)

    socket =
      socket
      |> assign(:selected_account_id, account_id)
      |> stream(:budgets, budgets, reset: true, dom_id: &"budget-#{&1.id}")

    {:noreply, socket}
  end
end

defmodule SpendableWeb.DashboardLive.Index do
  use SpendableWeb, :live_view

  alias Spendable.Transactions
  alias Spendable.Payments

  @impl true
  def mount(_params, _session, socket) do
    unfinalized_transactions =
      socket.assigns.current_user
      |> Transactions.list_unfinalized_transactions()

    payments =
      socket.assigns.current_user
      |> Payments.list_payments()

    socket =
      socket
      |> stream(:unfinalized_transactions, unfinalized_transactions)
      |> stream(:payments, payments)
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :create_payment, %{"transaction_id" => transaction_id}) do
    socket
    |> assign(:page_title, "Create Payment")
    |> assign(:transaction_id, transaction_id)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
    |> assign(:transaction_id, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>Dashboard</.header>

    <div class="flex flex-col gap-8">
      <div>
        <.header>
          Unfinalized Transactions
          <:subtitle>Transactions that need to be split into payments</:subtitle>
        </.header>

        <.table id="unfinalized-transactions-table" rows={@streams.unfinalized_transactions}>
          <:col :let={{dom_id, transaction}} label="Date" class="">
            <span id={dom_id} class="font-mono">
              {Calendar.strftime(transaction.booking_date, "%Y-%m-%d")}
            </span>
          </:col>

          <:col :let={{dom_id, transaction}} label="Description" class="hidden sm:table-cell">
            <span id={dom_id}>
              {transaction.counter_name}
              <%= if transaction.description && transaction.description != "" do %>
                - {transaction.description}
              <% end %>
            </span>
          </:col>

          <:col :let={{dom_id, transaction}} label="Amount" class="hidden md:table-cell">
            <span id={dom_id} class="font-mono">
              {"#{transaction.currency} #{transaction.amount / 100}"}
            </span>
          </:col>

          <:col :let={{dom_id, transaction}} label="Account" class="hidden lg:table-cell">
            <span id={dom_id}>{transaction.account.product} {transaction.account.owner_name}</span>
          </:col>

          <:col :let={{dom_id, transaction}} label="Actions">
            <div id={dom_id}>
              <.link patch={~p"/dashboard/create-payment/#{transaction.id}"}>
                <.button>Create Payment</.button>
              </.link>
            </div>
          </:col>
        </.table>
      </div>

      <div>
        <.header>
          Recent Payments
          <:subtitle>Payments created from transactions</:subtitle>
        </.header>

        <.table id="payments-table" rows={@streams.payments}>
          <:col :let={{dom_id, payment}} label="Date" class="">
            <span id={dom_id} class="font-mono">
              {Calendar.strftime(payment.booking_date, "%Y-%m-%d")}
            </span>
          </:col>

          <:col :let={{dom_id, payment}} label="Description" class="hidden sm:table-cell">
            <span id={dom_id}>
              {payment.counter_name}
              <%= if payment.description && payment.description != "" do %>
                - {payment.description}
              <% end %>
            </span>
          </:col>

          <:col :let={{dom_id, payment}} label="Amount" class="hidden md:table-cell">
            <span id={dom_id} class="font-mono">
              {"#{payment.currency} #{payment.amount / 100}"}
            </span>
          </:col>

          <:col :let={{dom_id, payment}} label="Budget" class="hidden lg:table-cell">
            <span id={dom_id}>{payment.budget.name}</span>
          </:col>

          <:col :let={{dom_id, payment}} label="Account" class="hidden xl:table-cell">
            <span id={dom_id}>{payment.account.product} {payment.account.owner_name}</span>
          </:col>
        </.table>
      </div>
    </div>

    <.modal
      :if={@live_action == :create_payment}
      id="payment-modal"
      show
      on_cancel={JS.patch(~p"/dashboard")}
    >
      <.live_component
        module={SpendableWeb.DashboardLive.PaymentFormComponent}
        id="payment-form"
        transaction_id={@transaction_id}
        current_user={@current_user}
        patch={~p"/dashboard"}
      />
    </.modal>
    """
  end

  @impl true
  def handle_info({SpendableWeb.DashboardLive.PaymentFormComponent, {:saved, _payment}}, socket) do
    # Refresh the data
    unfinalized_transactions =
      socket.assigns.current_user
      |> Transactions.list_unfinalized_transactions()

    payments =
      socket.assigns.current_user
      |> Payments.list_payments()

    {:noreply,
     socket
     |> stream(:unfinalized_transactions, unfinalized_transactions, reset: true)
     |> stream(:payments, payments, reset: true)}
  end
end

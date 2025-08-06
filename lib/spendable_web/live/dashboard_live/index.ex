defmodule SpendableWeb.DashboardLive.Index do
  use SpendableWeb, :live_view

  alias Spendable.Transactions
  alias Spendable.Payments
  alias Spendable.Accounts

  @impl true
  def mount(_params, _session, socket) do
    unfinalized_transactions =
      socket.assigns.current_user
      |> Transactions.list_unfinalized_transactions()

    payments =
      socket.assigns.current_user
      |> Payments.list_payments()

    accounts =
      socket.assigns.current_user
      |> Accounts.list_accounts()

    socket =
      socket
      |> stream(:unfinalized_transactions, unfinalized_transactions)
      |> stream(:payments, payments)
      |> stream(:accounts, accounts)
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
    <div class="space-y-8">
      <div class="mb-8">
        <.header class="pb-4">
          Dashboard
          <:subtitle>Your financial overview at a glance</:subtitle>
        </.header>
      </div>
      
    <!-- Account Balances Section -->
      <section class="bg-white rounded-xl border border-gray-200 shadow-sm">
        <div class="px-6 py-5 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900 flex items-center">
            <div class="w-2 h-2 bg-blue-500 rounded-full mr-3"></div>
            Account Balances
          </h2>
          <p class="mt-1 text-sm text-gray-600">Current balances from your connected accounts</p>
        </div>
        <div class="px-6 pb-6">
          <div class="mt-6">
            <.table id="accounts-table" rows={@streams.accounts}>
              <:col :let={{dom_id, account}} label="Account" class="">
                <div id={dom_id} class="py-2">
                  <div class="font-medium text-gray-900">{account.product}</div>
                  <div class="text-sm font-light">{account.owner_name}</div>
                </div>
              </:col>

              <:col :let={{dom_id, account}} label="IBAN" class="hidden md:table-cell">
                <span id={dom_id} class="font-mono text-sm text-gray-700 py-2">{account.iban}</span>
              </:col>

              <:col :let={{dom_id, account}} label="Balance" class="text-right">
                <div id={dom_id} class="py-2">
                  <%= if account.latest_balance do %>
                    <div class="text-right">
                      <span>
                        <.money_amount
                          amount={account.latest_balance.amount}
                          currency={account.latest_balance.currency}
                        />
                      </span>
                      <div class="text-xs text-gray-500 mt-1">
                        as of {Date.to_string(account.latest_balance.balance_date)}
                      </div>
                    </div>
                  <% else %>
                    <span class="text-gray-400 italic text-sm">No balance data</span>
                  <% end %>
                </div>
              </:col>
            </.table>
          </div>
        </div>
      </section>
      
    <!-- Unfinalized Transactions Section -->
      <%= if Enum.count(@streams.unfinalized_transactions) > 0 do %>
        <section class="bg-white rounded-xl border border-amber-200 shadow-sm">
          <div class="px-6 py-5 border-b border-amber-200 bg-amber-50">
            <h2 class="text-xl font-semibold text-amber-900 flex items-center">
              <div class="w-2 h-2 bg-amber-500 rounded-full mr-3"></div>
              Unfinalized Transactions
              <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
                {Enum.count(@streams.unfinalized_transactions)} pending
              </span>
            </h2>
            <p class="mt-1 text-sm text-amber-700">
              Transactions that need to be split into payments
            </p>
          </div>
          <div class="px-6 pb-6">
            <div class="mt-6">
              <.table id="unfinalized-transactions-table" rows={@streams.unfinalized_transactions}>
                <:col :let={{dom_id, transaction}} label="Date" class="">
                  <div id={dom_id} class="py-3">
                    <span class="font-mono text-sm text-gray-900">
                      {Calendar.strftime(transaction.booking_date, "%Y-%m-%d")}
                    </span>
                  </div>
                </:col>

                <:col :let={{dom_id, transaction}} label="Description" class="hidden sm:table-cell">
                  <div id={dom_id} class="py-3">
                    <div class="text-sm font-medium text-gray-900">{transaction.counter_name}</div>
                    <%= if transaction.description && transaction.description != "" do %>
                      <div class="text-sm text-gray-600">{transaction.description}</div>
                    <% end %>
                  </div>
                </:col>

                <:col
                  :let={{dom_id, transaction}}
                  label="Amount"
                  class="hidden md:table-cell text-right"
                >
                  <div id={dom_id} class="py-3">
                    <div class="text-right">
                      <span>
                        <.money_amount
                          amount={transaction.remaining_amount}
                          currency={transaction.currency}
                        />
                      </span>
                      <div class="text-xs text-gray-500 mt-1">
                        <%= if transaction.finalized_amount > 0 do %>
                          <span class="text-amber-600">
                            <.money_amount
                              amount={transaction.finalized_amount}
                              currency={transaction.currency}
                            />
                          </span>
                          of
                          <span>
                            <.money_amount
                              amount={transaction.amount}
                              currency={transaction.currency}
                            />
                          </span>
                          finalized
                        <% else %>
                          of
                          <span>
                            <.money_amount
                              amount={transaction.amount}
                              currency={transaction.currency}
                            />
                          </span>
                          total
                        <% end %>
                      </div>
                    </div>
                  </div>
                </:col>

                <:col :let={{dom_id, transaction}} label="Account" class="hidden lg:table-cell">
                  <div id={dom_id} class="py-3">
                    <div class="text-sm text-gray-900">{transaction.account.product}</div>
                    <div class="text-xs text-gray-600">{transaction.account.owner_name}</div>
                  </div>
                </:col>

                <:col :let={{dom_id, transaction}} label="Actions">
                  <div id={dom_id} class="py-3">
                    <.link patch={~p"/dashboard/create-payment/#{transaction.id}"}>
                      <.button class="bg-amber-600 hover:bg-amber-700">Create Payment</.button>
                    </.link>
                  </div>
                </:col>
              </.table>
            </div>
          </div>
        </section>
      <% end %>
      
    <!-- Recent Payments Section -->
      <section class="bg-white rounded-xl border border-gray-200 shadow-sm">
        <div class="px-6 py-5 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-900 flex items-center">
            <div class="w-2 h-2 bg-green-500 rounded-full mr-3"></div>
            Recent Payments
            <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              {Enum.count(@streams.payments)} total
            </span>
          </h2>
          <p class="mt-1 text-sm text-gray-600">Payments created from transactions</p>
        </div>
        <div class="px-6 pb-6">
          <div class="mt-6">
            <.table id="payments-table" rows={@streams.payments}>
              <:col :let={{dom_id, payment}} label="Date" class="">
                <div id={dom_id} class="py-3">
                  <span class="font-mono text-sm text-gray-900">
                    {Calendar.strftime(payment.booking_date, "%Y-%m-%d")}
                  </span>
                </div>
              </:col>

              <:col :let={{dom_id, payment}} label="Description" class="hidden sm:table-cell">
                <div id={dom_id} class="py-3">
                  <div class="text-sm font-medium text-gray-900">{payment.counter_name}</div>
                  <%= if payment.description && payment.description != "" do %>
                    <div class="text-sm text-gray-600">{payment.description}</div>
                  <% end %>
                </div>
              </:col>

              <:col :let={{dom_id, payment}} label="Amount" class="hidden md:table-cell text-right">
                <div id={dom_id} class="py-3">
                  <span>
                    <.money_amount amount={payment.amount} currency={payment.currency} />
                  </span>
                </div>
              </:col>

              <:col :let={{dom_id, payment}} label="Budget" class="hidden lg:table-cell">
                <div id={dom_id} class="py-3">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {payment.budget.name}
                  </span>
                </div>
              </:col>

              <:col :let={{dom_id, payment}} label="Account" class="hidden xl:table-cell">
                <div id={dom_id} class="py-3">
                  <div class="text-sm text-gray-900">{payment.account.product}</div>
                  <div class="text-xs text-gray-600">{payment.account.owner_name}</div>
                </div>
              </:col>
            </.table>
          </div>
        </div>
      </section>
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

    accounts =
      socket.assigns.current_user
      |> Accounts.list_accounts()

    {:noreply,
     socket
     |> stream(:unfinalized_transactions, unfinalized_transactions, reset: true)
     |> stream(:payments, payments, reset: true)
     |> stream(:accounts, accounts, reset: true)}
  end
end

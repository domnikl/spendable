defmodule SpendableWeb.DashboardLive.PaymentFormComponent do
  use SpendableWeb, :live_component

  alias Spendable.Payments
  alias Spendable.Transactions
  alias Spendable.Budgets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Create Payment from Transaction
        <:subtitle>Split this transaction into a payment with budget assignment</:subtitle>
      </.header>

      <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex justify-between items-start">
          <div>
            <h4 class="font-medium text-blue-900">Transaction Details</h4>
            <p class="text-sm text-blue-700">{@transaction.counter_name}</p>
          </div>
          <div class="text-right">
            <div class="text-lg font-semibold">
              <.money_amount amount={@transaction.amount} currency={@transaction.currency} />
            </div>
            <div class="text-sm text-blue-600">Total Amount</div>
          </div>
        </div>
        <div class="mt-3 flex justify-between text-sm">
          <div>
            <span class="text-blue-700">Already Finalized:</span>
            <span class="font-medium ml-1">
              <.money_amount amount={@transaction.finalized_amount} currency={@transaction.currency} />
            </span>
          </div>
          <div>
            <span class="text-blue-700">Remaining:</span>
            <span class="font-medium ml-1 text-green-700">
              <.money_amount amount={@transaction.remaining_amount} currency={@transaction.currency} />
            </span>
          </div>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="payment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:payment_id]} type="text" label="Payment ID" />
        <.input field={@form[:counter_name]} type="text" label="Counter Name" />
        <.input field={@form[:counter_iban]} type="text" label="Counter IBAN" />
        <.input field={@form[:amount]} type="number" label="Amount (in cents)" min="-999999999" />
        <.input field={@form[:currency]} type="text" label="Currency" />
        <.input field={@form[:booking_date]} type="date" label="Booking Date" />
        <.input field={@form[:value_date]} type="date" label="Value Date" />
        <.input field={@form[:purpose_code]} type="text" label="Purpose Code" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:budget_id]} type="select" label="Budget" options={@budgets} />
        <:actions>
          <.button phx-disable-with="Saving...">Create Payment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{transaction_id: transaction_id} = assigns, socket) do
    transaction = Transactions.get_transaction!(transaction_id)
    transaction_with_remaining = Transactions.add_remaining_amount(transaction)

    # Prefill form with remaining transaction data
    payment_attrs = %{
      payment_id: "PAY-#{transaction.transaction_id}",
      counter_name: transaction.counter_name,
      counter_iban: transaction.counter_iban,
      amount: transaction_with_remaining.remaining_amount,
      currency: transaction.currency,
      booking_date: transaction.booking_date,
      value_date: transaction.value_date,
      purpose_code: transaction.purpose_code,
      description: transaction.description
    }

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:transaction, transaction_with_remaining)
     |> assign(
       :form,
       to_form(
         Payments.change_payment_from_transaction(%Payments.Payment{}, transaction_with_remaining, payment_attrs)
       )
     )
     |> assign(:budgets, get_budget_options(assigns.current_user))}
  end

  @impl true
  def handle_event("validate", %{"payment" => payment_params}, socket) do
    changeset =
      Payments.change_payment_from_transaction(
        %Payments.Payment{},
        socket.assigns.transaction,
        payment_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"payment" => payment_params}, socket) do
    save_payment(socket, payment_params)
  end

  defp save_payment(socket, payment_params) do
    case Payments.create_payment_from_transaction(
           socket.assigns.current_user,
           socket.assigns.transaction,
           payment_params
         ) do
      {:ok, payment} ->
        notify_parent({:saved, payment})

        {:noreply,
         socket
         |> put_flash(:info, "Payment created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :exceeds_remaining_amount} ->
        {:noreply, 
         socket
         |> put_flash(:error, "Payment amount exceeds remaining transaction amount")
         |> assign(form: to_form(socket.assigns.form.source, action: :validate))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp get_budget_options(user) do
    Spendable.Budgets.list_active_budgets(user)
    |> Enum.map(fn budget -> {budget.name, budget.id} end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

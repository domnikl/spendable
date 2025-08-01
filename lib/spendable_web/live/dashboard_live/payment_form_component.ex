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

    # Prefill form with transaction data
    payment_attrs = %{
      payment_id: "PAY-#{transaction.transaction_id}",
      counter_name: transaction.counter_name,
      counter_iban: transaction.counter_iban,
      amount: transaction.amount,
      currency: transaction.currency,
      booking_date: transaction.booking_date,
      value_date: transaction.value_date,
      purpose_code: transaction.purpose_code,
      description: transaction.description
    }

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:transaction, transaction)
     |> assign(
       :form,
       to_form(
         Payments.change_payment_from_transaction(%Payments.Payment{}, transaction, payment_attrs)
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
        # Mark transaction as finalized
        {:ok, _} = Transactions.set_transaction_finalized(socket.assigns.transaction, true)

        notify_parent({:saved, payment})

        {:noreply,
         socket
         |> put_flash(:info, "Payment created successfully")
         |> push_patch(to: socket.assigns.patch)}

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

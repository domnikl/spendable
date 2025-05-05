defmodule SpendableWeb.TransactionLive.FormComponent do
  use SpendableWeb, :live_component

  alias Spendable.Transactions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage transaction records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="transaction-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:transaction_id]} type="text" label="Transaction" />
        <.input field={@form[:counter_name]} type="text" label="Counter name" />
        <.input field={@form[:counter_iban]} type="text" label="Counter iban" />
        <.input field={@form[:amount]} type="number" label="Amount" />
        <.input field={@form[:currency]} type="text" label="Currency" />
        <.input field={@form[:booking_date]} type="date" label="Booking date" />
        <.input field={@form[:value_date]} type="date" label="Value date" />
        <.input field={@form[:purpose_code]} type="text" label="Purpose code" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Transaction</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{transaction: transaction} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Transactions.change_transaction(transaction))
     end)}
  end

  @impl true
  def handle_event("validate", %{"transaction" => transaction_params}, socket) do
    changeset = Transactions.change_transaction(socket.assigns.transaction, transaction_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"transaction" => transaction_params}, socket) do
    save_transaction(socket, socket.assigns.action, transaction_params)
  end

  defp save_transaction(socket, :edit, transaction_params) do
    case Transactions.update_transaction(socket.assigns.transaction, transaction_params) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Transaction updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_transaction(socket, :new, transaction_params) do
    case Transactions.create_transaction(transaction_params) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Transaction created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

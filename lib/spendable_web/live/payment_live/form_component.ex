defmodule SpendableWeb.PaymentLive.FormComponent do
  use SpendableWeb, :live_component

  alias Spendable.Payments
  alias Spendable.Budgets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage payment records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="payment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:payment_id]} type="text" label="Payment ID" />
        <.input field={@form[:counter_name]} type="text" label="Counter name" />
        <.input field={@form[:counter_iban]} type="text" label="Counter iban" />
        <.input field={@form[:amount]} type="number" label="Amount (in cents)" min="-999999999" />
        <.input field={@form[:currency]} type="text" label="Currency" />
        <.input field={@form[:booking_date]} type="date" label="Booking date" />
        <.input field={@form[:value_date]} type="date" label="Value date" />
        <.input field={@form[:purpose_code]} type="text" label="Purpose code" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:budget_id]} type="select" label="Budget" options={@budgets} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Payment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{payment: payment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Payments.change_payment(payment))
     end)
     |> assign(:budgets, get_budget_options(assigns.current_user))}
  end

  @impl true
  def handle_event("validate", %{"payment" => payment_params}, socket) do
    changeset = Payments.change_payment(socket.assigns.payment, payment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"payment" => payment_params}, socket) do
    save_payment(socket, socket.assigns.action, payment_params)
  end

  defp save_payment(socket, :edit, payment_params) do
    case Payments.update_payment(socket.assigns.payment, payment_params) do
      {:ok, payment} ->
        notify_parent({:saved, payment})

        {:noreply,
         socket
         |> put_flash(:info, "Payment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_payment(socket, :new, payment_params) do
    case Payments.create_payment(socket.assigns.current_user, payment_params) do
      {:ok, payment} ->
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

defmodule SpendableWeb.BudgetsLive.FormComponent do
  use SpendableWeb, :live_component

  alias Spendable.Budgets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage budget records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="budget-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:amount]} type="number" label="Amount (in cents)" />
        <.input field={@form[:due_date]} type="date" label="Due Date" />
        <.input
          field={@form[:interval]}
          type="select"
          label="Interval"
          options={[
            {"Monthly", :monthly},
            {"Quarterly", :quarterly},
            {"Yearly", :yearly},
            {"One Time", :one_time}
          ]}
        />
        <.input field={@form[:account_id]} type="select" label="Account" options={@accounts} />
        <.input
          field={@form[:parent_id]}
          type="select"
          label="Parent Budget (optional)"
          options={@parent_budgets}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Budget</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{budget: budget} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Budgets.change_budget(budget))
     end)
     |> assign(:accounts, get_account_options(assigns.current_user))
     |> assign(:parent_budgets, get_parent_budget_options(assigns.current_user))}
  end

  @impl true
  def handle_event("validate", %{"budget" => budget_params}, socket) do
    changeset = Budgets.change_budget(socket.assigns.budget, budget_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"budget" => budget_params}, socket) do
    save_budget(socket, socket.assigns.action, budget_params)
  end

  defp save_budget(socket, :edit, budget_params) do
    case Budgets.update_budget(socket.assigns.budget, budget_params) do
      {:ok, budget} ->
        notify_parent({:saved, budget})

        {:noreply,
         socket
         |> put_flash(:info, "Budget updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_budget(socket, :new, budget_params) do
    case Budgets.create_budget(socket.assigns.current_user, budget_params) do
      {:ok, budget} ->
        notify_parent({:saved, budget})

        {:noreply,
         socket
         |> put_flash(:info, "Budget created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp get_account_options(user) do
    Spendable.Accounts.list_accounts(user)
    |> Enum.map(fn account -> {"#{account.product} - #{account.owner_name}", account.id} end)
  end

  defp get_parent_budget_options(user) do
    [{"None", nil}] ++
      (Spendable.Budgets.get_parent_budgets(user)
       |> Enum.map(fn budget -> {budget.name, budget.id} end))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

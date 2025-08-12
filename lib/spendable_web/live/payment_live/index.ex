defmodule SpendableWeb.PaymentLive.Index do
  use SpendableWeb, :live_view

  alias Spendable.Payments
  alias Spendable.Payments.Payment
  alias Spendable.Accounts
  alias Spendable.Budgets

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    accounts = Accounts.list_accounts(user)
    budgets = Budgets.list_budgets(user)

    # Initialize empty filters
    filters = %{}
    pagination_result = Payments.list_payments(user, 1, 25, filters)

    {:ok,
     socket
     |> stream(:payments, pagination_result.payments)
     |> assign(:pagination, pagination_result)
     |> assign(:accounts, accounts)
     |> assign(:budgets, budgets)
     |> assign(:filters, filters)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Payment")
    |> assign(:payment, Payments.get_payment!(socket.assigns.current_user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Payment")
    |> assign(:payment, %Payment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Payments")
    |> assign(:payment, nil)
  end

  @impl true
  def handle_info({SpendableWeb.PaymentLive.FormComponent, {:saved, payment}}, socket) do
    {:noreply, stream_insert(socket, :payments, payment, at: -1)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    payment = Payments.get_payment!(socket.assigns.current_user, id)
    {:ok, _} = Payments.delete_payment(payment)

    {:noreply, stream_delete(socket, :payments, payment)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page = String.to_integer(page)

    pagination_result =
      Payments.list_payments(
        socket.assigns.current_user,
        page,
        25,
        socket.assigns.filters
      )

    {:noreply,
     socket
     |> stream(:payments, pagination_result.payments, reset: true)
     |> assign(:pagination, pagination_result)}
  end

  @impl true
  def handle_event("filter_payments", %{"clear" => "true"}, socket) do
    # Clear all filters
    filters = %{}
    pagination_result = Payments.list_payments(socket.assigns.current_user, 1, 25, filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> stream(:payments, pagination_result.payments, reset: true)
     |> assign(:pagination, pagination_result)}
  end

  @impl true
  def handle_event("filter_payments", params, socket) do
    filters = build_filters(params)

    pagination_result = Payments.list_payments(socket.assigns.current_user, 1, 25, filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> stream(:payments, pagination_result.payments, reset: true)
     |> assign(:pagination, pagination_result)}
  end

  defp build_filters(params) do
    filters = %{}

    filters =
      case Map.get(params, "account_id") do
        "" -> filters
        nil -> filters
        account_id -> Map.put(filters, :account_id, String.to_integer(account_id))
      end

    filters =
      case Map.get(params, "budget_id") do
        "" -> filters
        nil -> filters
        budget_id -> Map.put(filters, :budget_id, String.to_integer(budget_id))
      end

    filters =
      case Map.get(params, "date_from") do
        "" ->
          filters

        nil ->
          filters

        date_from ->
          case Date.from_iso8601(date_from) do
            {:ok, date} -> Map.put(filters, :date_from, date)
            {:error, _} -> filters
          end
      end

    filters =
      case Map.get(params, "date_to") do
        "" ->
          filters

        nil ->
          filters

        date_to ->
          case Date.from_iso8601(date_to) do
            {:ok, date} -> Map.put(filters, :date_to, date)
            {:error, _} -> filters
          end
      end

    filters =
      case Map.get(params, "search") do
        "" -> filters
        nil -> filters
        search -> Map.put(filters, :search, String.trim(search))
      end

    filters =
      case Map.get(params, "amount_min") do
        "" ->
          filters

        nil ->
          filters

        amount_str ->
          case Integer.parse(String.replace(amount_str, ~r/[^\d]/, "")) do
            {amount, _} -> Map.put(filters, :amount_min, amount)
            :error -> filters
          end
      end

    filters =
      case Map.get(params, "amount_max") do
        "" ->
          filters

        nil ->
          filters

        amount_str ->
          case Integer.parse(String.replace(amount_str, ~r/[^\d]/, "")) do
            {amount, _} -> Map.put(filters, :amount_max, amount)
            :error -> filters
          end
      end

    filters
  end
end

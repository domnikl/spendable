defmodule SpendableWeb.AccountsLive.Index do
  use SpendableWeb, :live_view

  import SaladUI.Checkbox

  @impl true
  def mount(_params, _session, socket) do
    accounts =
      socket.assigns.current_user
      |> Spendable.Accounts.list_accounts()

    socket =
      socket
      |> assign(:accounts, accounts)
      |> assign(:page_title, "Accounts")

    {:ok, socket}
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>Accounts</.header>

    <.table id="accounts-table" rows={@accounts}>
      <:col :let={account} label="Name" class="">
        {account.product} {account.owner_name}
      </:col>

      <:col :let={account} label="IBAN" class="hidden sm:table-cell">
        {account.iban}
      </:col>
      <:col :let={account} label="BIC" class="hidden md:table-cell">
        {account.bic}
      </:col>
      <:col :let={account} label="Currency" class="hidden lg:table-cell">
        {account.currency}
      </:col>

      <:col :let={account} label="Active?">
        <div className="flex items-center space-x-2">
          <.checkbox
            id="checked"
            value={account.active}
            phx-click="toggle_account_active"
            phx-value-account_id={account.account_id}
            phx-value-active={account.active}
          />
          <.label for="checked"></.label>
        </div>
      </:col>
    </.table>
    """
  end

  defp toggle_account_active(socket, account_id, active) do
    account = Spendable.Accounts.get_account!(socket.assigns.current_user, account_id)

    IO.inspect(account, label: "Account")
    IO.inspect(active, label: "Active")

    case Spendable.Accounts.set_active_account(account, active) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:accounts, Spendable.Accounts.list_accounts(socket.assigns.current_user))
         |> put_flash(:info, "Account updated.")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "toggle_account_active",
        %{"account_id" => account_id, "value" => "true"},
        socket
      ) do
    socket |> toggle_account_active(account_id, true)
  end

  @impl true
  def handle_event("toggle_account_active", %{"account_id" => account_id}, socket) do
    socket |> toggle_account_active(account_id, false)
  end
end

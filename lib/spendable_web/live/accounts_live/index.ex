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
      |> stream(:accounts, accounts)
      |> assign(:page_title, "Accounts")

    {:ok, socket}
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>Accounts</.header>

    <.table id="accounts-table" rows={@streams.accounts}>
      <:col :let={{dom_id, account}} label="Name" class="">
        <span id={dom_id}>{account.product} {account.owner_name}</span>
      </:col>

      <:col :let={{dom_id, account}} label="IBAN" class="hidden sm:table-cell">
        <span id={dom_id}>{account.iban}</span>
      </:col>
      <:col :let={{dom_id, account}} label="BIC" class="hidden md:table-cell">
        <span id={dom_id}>{account.bic}</span>
      </:col>
      <:col :let={{dom_id, account}} label="Currency" class="hidden lg:table-cell">
        <span id={dom_id}>{account.currency}</span>
      </:col>

      <:col :let={{dom_id, account}} label="Active?">
        <div className="flex items-center space-x-2" id={dom_id}>
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

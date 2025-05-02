defmodule SpendableWeb.AccountsLive.Index do
  use SpendableWeb, :live_view

  import SpendableWeb.Components.Table
  import SpendableWeb.Components.CheckboxField

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
  def render(assigns) do
    ~H"""
    <.h1>Accounts</.h1>

    <.table variant="hoverable" color="base" class="mt-5">
      <:header>Name</:header>
      <:header>IBAN</:header>
      <:header>Currency</:header>
      <:header>Active?</:header>

      <.tr :for={account <- @accounts}>
        <.td>
          {account.product} {account.owner_name}
        </.td>
        <.td>
          {account.iban}
        </.td>
        <.td>
          {account.currency}
        </.td>
        <.td>
          <.checkbox_field
            color="primary"
            name={"active#{account.account_id}"}
            value="true"
            checked={account.active}
            class="mr-2"
            phx-click="toggle_account_active"
            phx-value-account_id={account.account_id}
            phx-value-active={account.active}
          />
        </.td>
      </.tr>
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

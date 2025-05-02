defmodule SpendableWeb.AccountsLive.Index do
  use SpendableWeb, :live_view

  import SpendableWeb.Components.Table

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
      <:header>Currency</:header>

      <.tr :for={account <- @accounts}>
        <.td>
          {account.product} {account.owner_name}
        </.td>
        <.td>
          {account.currency}
        </.td>
      </.tr>
    </.table>
    """
  end
end

defmodule SpendableWeb.PaymentLive.Index do
  use SpendableWeb, :live_view

  alias Spendable.Payments
  alias Spendable.Payments.Payment

  @impl true
  def mount(_params, _session, socket) do
    payments =
      socket.assigns.current_user
      |> Payments.list_payments()

    {:ok, stream(socket, :payments, payments)}
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
end

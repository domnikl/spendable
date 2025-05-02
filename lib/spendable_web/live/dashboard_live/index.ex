defmodule SpendableWeb.DashboardLive.Index do
  use SpendableWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.h1>Dashboard</.h1>

    <div class="flex flex-col gap-4">
      <.link href={~p"/setup"}>Setup</.link>
    </div>
    """
  end
end

defmodule SpendableWeb.InstitutionLive.Index do
  use SpendableWeb, :live_view

  import SpendableWeb.Components.Combobox
  import SpendableWeb.Components.Button

  def mount(_params, _session, socket) do
    {:ok, institutions} = Gocardless.Client.get_institutions("DE")
    {:ok, assign(socket, institutions: institutions, next_active: false)}
  end

  def render(assigns) do
    ~H"""
    <h1>Institutions</h1>

    <form phx-change="institution_changed">
      <div class="flex flex-col gap-4">
        <.combobox
          name="institution"
          searchable
          placeholder="Select your bank"
          phx-change="institution_changed"
        >
          <:option :for={institution <- @institutions} value={institution.id}>
            {institution.name}
          </:option>
        </.combobox>

        <div class="flex flex-col gap-4">
          <.button disabled={!@next_active} phx-click="next">
            Next
          </.button>
        </div>
      </div>
    </form>
    """
  end

  def handle_event("institution_changed", %{"institution" => ""}, socket) do
    {:noreply, assign(socket, next_active: false, institution_id: nil)}
  end

  def handle_event("institution_changed", %{"institution" => institution_id}, socket) do
    {:noreply, assign(socket, next_active: true, institution_id: institution_id)}
  end

  def handle_event("next", _params, socket) do
    socket
    |> redirect(external: ~p"/setup/institution/#{socket.assigns.institution_id}")

    {:noreply, socket}
  end
end

defmodule SpendableWeb.InstitutionLive.Index do
  use SpendableWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, institutions} = Gocardless.Client.get_institutions("DE")
    filtered = Enum.take(institutions, 10)
    {:ok, assign(socket, institutions: institutions, filtered: filtered)}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Banks
      <:subtitle>Choose your bank to setup your accounts from.</:subtitle>
    </.header>

    <div>
      <!-- a search form to filter the institutions -->

      <.input
        name="filter"
        type="text"
        value=""
        placeholder="Search for your bank"
        phx-keyup="filter_changed"
      />
    </div>

    <div class="flex flex-col gap-4">
      <.table id="institution-table" rows={@filtered}>
        <:col :let={institution} label="Name">
          <div class="flex flex-row items-center">
            <img src={institution.logo} alt={institution.name} class="w-8 h-8 mr-2" />
            {institution.name}
          </div>
        </:col>
        <:col :let={institution} label="BIC" class="">
          {institution.bic}
        </:col>
        <:col :let={institution} label="Actions" class="">
          <.link navigate={"/setup/institution/#{institution.id}"} class="flex items-center">
            Setup <.icon name="hero-chevron-right" class="ml-2" />
          </.link>
        </:col>
      </.table>
      
    <!-- if nothing was found, show a message -->
      <div :if={length(@filtered) == 0} class="text-center">
        <p>No institutions found.</p>
        <p>Try a different search term.</p>
      </div>
    </div>
    """
  end

  def handle_event("filter_changed", %{"value" => ""}, socket) do
    {:noreply, assign(socket, filtered: Enum.take(socket.assigns.institutions, 10))}
  end

  def handle_event("filter_changed", %{"value" => filter}, socket) do
    filtered =
      socket.assigns.institutions
      |> Enum.filter(fn institution ->
        String.contains?(String.downcase(institution.name), String.downcase(filter))
      end)

    {:noreply, assign(socket, filtered: filtered)}
  end
end

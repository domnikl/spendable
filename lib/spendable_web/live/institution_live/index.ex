defmodule SpendableWeb.InstitutionLive.Index do
  use SpendableWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, institutions} = Gocardless.Client.get_institutions("DE")

    socket =
      socket
      |> assign(:institutions, institutions)
      |> assign(:page_title, "Banks")
      |> stream(:filtered, Enum.take(institutions, 10))
      |> assign(:form, to_form(%{}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Banks
      <:subtitle>Choose your bank to setup your accounts from.</:subtitle>
    </.header>

    <div>
      <.form for={@form} phx-change="filter_changed">
        <.input
          field={@form[:filter]}
          placeholder="Search for your bank"
          phx-keyup="filter_changed"
          phx-debounce="200"
        />
      </.form>
    </div>

    <div class="flex flex-col gap-4">
      <.table id="institution-table" rows={@streams.filtered}>
        <:col :let={{dom_id, institution}} label="Name">
          <div class="flex flex-row items-center" id={dom_id}>
            <img src={institution.logo} alt={institution.name} class="w-8 h-8 mr-2" />
            {institution.name}
          </div>
        </:col>
        <:col :let={{dom_id, institution}} label="BIC" class="">
          <div id={dom_id}>{institution.bic}</div>
        </:col>
        <:col :let={{dom_id, institution}} label="Actions" class="">
          <.link
            navigate={"/setup/institution/#{institution.id}"}
            class="flex items-center"
            id={dom_id}
          >
            Setup <.icon name="hero-chevron-right" class="ml-2" />
          </.link>
        </:col>

        <div :if={length(@streams.filtered) == 0} class="text-center only:block">
          <p>No institutions found.</p>
          <p>Try a different search term.</p>
        </div>
      </.table>
    </div>
    """
  end

  def handle_event("filter_changed", %{"value" => ""}, socket) do
    socket =
      socket
      |> stream(:filtered, Enum.take(socket.assigns.institutions, 10), reset: true)

    {:noreply, socket}
  end

  def handle_event("filter_changed", %{"value" => filter}, socket) do
    filtered =
      socket.assigns.institutions
      |> Enum.filter(fn institution ->
        String.contains?(String.downcase(institution.name), String.downcase(filter))
      end)
      |> Enum.take(10)

    socket =
      socket
      |> stream(:filtered, filtered, reset: true)

    {:noreply, socket}
  end
end

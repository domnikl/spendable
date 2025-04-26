defmodule Gocardless.Client do
  use GenServer

  @client_name __MODULE__

  @doc false
  def start_link(config) do
    initial_state = %{config: config}
    GenServer.start_link(__MODULE__, initial_state, name: @client_name)
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc """
  Fetches the configuration for the Gocardless client.
  """
  def get_institutions do
    GenServer.call(__MODULE__, :get_institutions)
  end

  @doc false
  def handle_call(:get_institutions, _from, state) do
    access_token_response = get_access_token(state)

    response =
      case access_token_response do
        {:ok, %{"access" => access_token}} ->
          response =
            Finch.build(
              :get,
              "#{state.config[:config][:base_url]}/institutions/",
              [
                {"Authorization", "Bearer #{access_token}"},
                {"Accept", "application/json"}
              ]
            )
            |> Finch.request(Gocardless.Finch)

          case response do
            {:ok, %Finch.Response{status: 200, body: body}} ->
              {:ok, Jason.decode!(body)}

            {:ok, %Finch.Response{status: status, body: body}} ->
              {:error, "Error fetching institutions: #{status} - #{body}"}

            {:error, reason} ->
              {:error, "Error fetching institutions: #{reason}"}
          end

        {:error, reason} ->
          {:error, "Error fetching access token: #{reason}"}
      end

    {:reply, response, state}
  end

  defp get_access_token(state) do
    config = state.config[:config]
    base_url = config[:base_url]

    body =
      %{
        secret_id: config[:secret_id],
        secret_key: config[:secret_key]
      }
      |> Jason.encode!()

    Finch.build(
      :post,
      "#{base_url}/token/new/",
      [
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ],
      body
    )
    |> Finch.request(Gocardless.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, "Error fetching access token: #{status} - #{body}"}

      {:error, reason} ->
        {:error, "Error fetching access token: #{reason}"}
    end
  end
end

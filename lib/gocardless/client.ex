defmodule Gocardless.Client do
  use GenServer

  @config Application.compile_env(:spendable, Gocardless.Client)

  @moduledoc """
  A module for interacting with the Gocardless API.
  """

  alias Gocardless.GocardlessApi

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    IO.inspect(@config, label: "Gocardless Client Config")

    {:ok, token} = get_access_token()

    {:ok,
     %{
       access_token: token[:access_token],
       refresh_token: token[:refresh_token],
       access_expires: token[:access_expires]
     }}
  end

  @doc """
  Fetches the list of institutions from the Gocardless API.
  """
  def get_institutions(country) do
    GenServer.call(__MODULE__, [:get_institutions, country])
  end

  def handle_call([:get_institutions, country], _from, state) do
    {:ok, s} = refresh_token(state)

    institutions = GocardlessApi.get_institutions(s.access_token, country)
    {:reply, institutions, s}
  end

  defp get_access_token() do
    response = GocardlessApi.get_access_token(@config[:secret_id], @config[:secret_key])

    case response do
      {:ok, token} ->
        # TODO: remove this
        token = %{
          access: token.access,
          refresh: token.refresh,
          access_expires: 1
        }

        access_expires = DateTime.add(DateTime.utc_now(), token.access_expires, :second)

        {:ok,
         %{
           access_token: token.access,
           refresh_token: token.refresh,
           access_expires: access_expires
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp refresh_token(state = %{refresh_token: refresh}) do
    if DateTime.compare(DateTime.utc_now(), state.access_expires) == :gt do
      IO.inspect(state, label: "Refreshing token")

      {:ok, response} = GocardlessApi.refresh_token(refresh)

      state = Map.put(state, :access_token, response.access)

      state =
        Map.put(
          state,
          :access_expires,
          DateTime.add(DateTime.utc_now(), response.access_expires, :second)
        )

      {:ok, state}
    else
      {:ok, state}
    end
  end
end

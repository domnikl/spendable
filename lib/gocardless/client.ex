defmodule Gocardless.Client do
  use GenServer

  @config Application.compile_env(:spendable, Gocardless.Client)

  @moduledoc """
  A module for interacting with the Gocardless API.
  """

  alias Gocardless.GocardlessApi.PostAgreementRequest
  alias Gocardless.GocardlessApi.PostAgreementResponse
  alias Gocardless.GocardlessApi.PostRequisitionRequest
  alias Gocardless.GocardlessApi

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
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

  @doc """
  Fetches a specific institution from the Gocardless API.
  """
  def get_institution(id) do
    GenServer.call(__MODULE__, [:get_institution, id])
  end

  @doc """
  Fetches a specific account's details from the Gocardless API.
  """
  def get_account_details(id) do
    GenServer.call(__MODULE__, [:get_account_details, id])
  end

  @doc """
  Fetches a specific requisition from the Gocardless API.
  """
  def get_requisition(id) do
    GenServer.call(__MODULE__, [:get_requisition, id])
  end

  @spec create_agreement(PostAgreementRequest.t()) ::
          {:ok, PostAgreementResponse.t()} | {:error, any()}
  def create_agreement(body) do
    GenServer.call(__MODULE__, [
      :create_agreement,
      body
    ])
  end

  @spec create_requisition(PostRequisitionRequest.t()) ::
          {:ok, PostAgreementResponse.t()} | {:error, any()}
  def create_requisition(body) do
    GenServer.call(__MODULE__, [
      :create_requisition,
      body
    ])
  end

  def handle_call([:get_institutions, country], _from, state) do
    {:ok, s} = refresh_token(state)
    {:reply, GocardlessApi.get_institutions(s.access_token, country), s}
  end

  def handle_call([:get_institution, id], _from, state) do
    {:ok, s} = refresh_token(state)
    {:reply, GocardlessApi.get_institution(s.access_token, id), s}
  end

  def handle_call([:create_agreement, body], _from, state) do
    {:ok, s} = refresh_token(state)
    {:reply, GocardlessApi.post_agreement(s.access_token, body), s}
  end

  def handle_call([:create_requisition, body], _from, state) do
    {:ok, s} = refresh_token(state)

    body =
      Map.put(body, :redirect, "#{@config[:redirect_uri]}?reference=#{body.reference}")

    {:reply, GocardlessApi.post_requisition(s.access_token, body), s}
  end

  def handle_call([:get_requisition, id], _from, state) do
    {:ok, s} = refresh_token(state)
    {:reply, GocardlessApi.get_requisition(s.access_token, id), s}
  end

  def handle_call([:get_account_details, id], _from, state) do
    {:ok, s} = refresh_token(state)
    {:reply, GocardlessApi.get_account_details(s.access_token, id), s}
  end

  defp get_access_token() do
    response = GocardlessApi.get_access_token(@config[:secret_id], @config[:secret_key])

    case response do
      {:ok, token} ->
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

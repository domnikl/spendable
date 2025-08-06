defmodule Gocardless.GocardlessApi do
  use Knigge, otp_app: :spendable, default: Gocardless.GocardlessApiImpl

  # 1. add an alias for the response module
  alias __MODULE__.GetTransactionsResponse
  alias __MODULE__.PostRequisitionResponse
  alias __MODULE__.GetAccessTokenResponse
  alias __MODULE__.RefreshTokenResponse
  alias __MODULE__.GetInstitutionsResponse
  alias __MODULE__.GetInstitutionResponse
  alias __MODULE__.PostAgreementRequest
  alias __MODULE__.PostAgreementResponse
  alias __MODULE__.PostRequisitionRequest
  alias __MODULE__.PostRequisitionResponse
  alias __MODULE__.GetRequisitionResponse
  alias __MODULE__.GetAccountDetailsResponse
  alias __MODULE__.GetBalancesResponse

  @type get_access_token_response :: {:ok, GetAccessTokenResponse.t()} | {:error, any()}
  @callback get_access_token(secret_id :: String.t(), secret_key :: String.t()) ::
              get_access_token_response()

  @type refresh_token_response :: {:ok, RefreshTokenResponse.t()} | {:error, any()}
  @callback refresh_token(refresh_token :: String.t()) ::
              {:ok, RefreshTokenResponse.t()} | {:error, any()}

  @type get_institutions_response :: {:ok, GetInstitutionsResponse.t()} | {:error, any()}
  @callback get_institutions(access_token :: String.t(), country :: String.t()) ::
              {:ok, GetInstitutionsResponse.t()} | {:error, any()}

  @type get_institution_response :: {:ok, GetInstitutionResponse.t()} | {:error, any()}
  @callback get_institution(
              access_token :: String.t(),
              institution_id :: String.t()
            ) ::
              {:ok, GetInstitutionResponse.t()} | {:error, any()}

  @type get_account_details_response :: {:ok, GetAccountDetailsResponse.t()} | {:error, any()}
  @callback get_account_details(
              access_token :: String.t(),
              account_id :: String.t()
            ) ::
              {:ok, GetAccountDetailsResponse.t()} | {:error, any()}

  @type agreement_response :: {:ok, PostAgreementResponse.t()} | {:error, any()}
  @callback post_agreement(access_token :: String.t(), PostAgreementRequest.t()) ::
              {:ok, PostAgreementResponse.t()} | {:error, any()}

  @type requisition_response :: {:ok, PostRequisitionResponse.t()} | {:error, any()}
  @callback post_requisition(access_token :: String.t(), PostRequisitionRequest.t()) ::
              {:ok, PostRequisitionResponse.t()} | {:error, any()}

  @type get_requisition_response :: {:ok, GetRequisitionResponse.t()} | {:error, any()}
  @callback get_requisition(
              access_token :: String.t(),
              requisition_id :: String.t()
            ) ::
              {:ok, GetRequisitionResponse.t()} | {:error, any()}

  @type get_transactions_response :: {:ok, GetTransactionsResponse.t()} | {:error, any()}
  @callback get_transactions(
              access_token :: String.t(),
              account_id :: String.t()
            ) ::
              {:ok, GetTransactionsResponse.t()} | {:error, any()}

  @type get_balances_response :: {:ok, GetBalancesResponse.t()} | {:error, any()}
  @callback get_balances(
              access_token :: String.t(),
              account_id :: String.t()
            ) ::
              {:ok, GetBalancesResponse.t()} | {:error, any()}
end

defmodule Gocardless.GocardlessApiImpl do
  alias Gocardless.GocardlessApi.GetTransactionsResponse
  alias Gocardless.GocardlessApi.GetAccountDetailsResponse
  alias Gocardless.GocardlessApi.GetBalancesResponse
  alias Gocardless.GocardlessApi.GetRequisitionResponse
  alias Gocardless.GocardlessApi.RefreshTokenResponse
  alias Gocardless.GocardlessApi.GetInstitutionsResponse
  alias Gocardless.GocardlessApi.GetInstitutionResponse
  alias Gocardless.GocardlessApi.GetAccessTokenResponse
  alias Gocardless.GocardlessApi.PostAgreementResponse
  alias Gocardless.GocardlessApi.PostRequisitionRequest
  alias Gocardless.GocardlessApi.PostRequisitionResponse
  @behaviour Gocardless.GocardlessApi

  def get_access_token(secret_id, secret_key) do
    "/token/new/"
    |> build_request(
      method: :post,
      body: %{
        secret_id: secret_id,
        secret_key: secret_key
      },
      headers: [
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetAccessTokenResponse.new(json)}

      error ->
        error
    end
  end

  def refresh_token(refresh_token) do
    "/token/refresh/"
    |> build_request(
      method: :post,
      headers: [{"Content-Type", "application/json"}, {"Accept", "application/json"}],
      body: %{
        refresh: refresh_token
      }
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, RefreshTokenResponse.new(json)}

      error ->
        error
    end
  end

  def get_institutions(access_token, country) do
    "/institutions/?country=#{country}"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetInstitutionsResponse.new(json)}

      error ->
        error
    end
  end

  def get_institution(access_token, id) do
    "/institutions/#{id}/"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetInstitutionResponse.new(json)}

      error ->
        error
    end
  end

  def post_requisition(access_token, body) do
    "/requisitions/"
    |> build_request(
      method: :post,
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"},
        {"Content-Type", "application/json"}
      ],
      body: body
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, PostRequisitionResponse.new(json)}

      error ->
        error
    end
  end

  def get_requisition(access_token, requisition_id) do
    "/requisitions/#{requisition_id}/"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetRequisitionResponse.new(json)}

      error ->
        error
    end
  end

  def get_transactions(access_token, account_id) do
    "/accounts/#{account_id}/transactions/"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetTransactionsResponse.new(json)}

      error ->
        error
    end
  end

  def get_account_details(access_token, account_id) do
    "/accounts/#{account_id}/details/"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetAccountDetailsResponse.new(json)}

      error ->
        error
    end
  end

  def get_balances(access_token, account_id) do
    "/accounts/#{account_id}/balances/"
    |> build_request(
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"}
      ]
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, GetBalancesResponse.new(json)}

      error ->
        error
    end
  end

  def post_agreement(access_token, body) do
    "/agreements/enduser/"
    |> build_request(
      method: :post,
      headers: [
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{access_token}"},
        {"Content-Type", "application/json"}
      ],
      body: body
    )
    |> Finch.request(GocardlessApi)
    |> parse_as_json()
    |> case do
      {:ok, json} ->
        {:ok, PostAgreementResponse.new(json)}

      error ->
        error
    end
  end

  defp build_request(path, opts) do
    request_url = "https://bankaccountdata.gocardless.com/api/v2#{path}"

    body =
      if opts[:body] do
        Jason.encode!(opts[:body])
      else
        nil
      end

    Finch.build(
      opts[:method] || :get,
      request_url,
      opts[:headers] || [],
      body
    )
  end

  defp parse_as_json({:ok, %Finch.Response{status: 200, body: body}}) do
    Jason.decode(body)
  end

  defp parse_as_json({:ok, %Finch.Response{status: 201, body: body}}) do
    Jason.decode(body)
  end

  defp parse_as_json({:ok, %Finch.Response{status: error_code, body: body, headers: headers}}) do
    {:error, {:http, error_code, body, headers}}
  end

  defp parse_as_json({:error, _exception} = error), do: error
end

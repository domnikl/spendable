defmodule Gocardless.GocardlessApi do
  use Knigge, otp_app: :spendable, default: Gocardless.GocardlessApiImpl

  # 1. add an alias for the response module
  alias __MODULE__.GetAccessTokenResponse

  @type get_access_token_response :: {:ok, GetAccessTokenResponse.t()} | {:error, any()}
  @callback get_access_token(secret_id :: String.t(), secret_key :: String.t()) ::
              get_access_token_response()

  @type refresh_token_response :: {:ok, RefreshTokenResponse.t()} | {:error, any()}
  @callback refresh_token(refresh_token :: String.t()) ::
              {:ok, RefreshTokenResponse.t()} | {:error, any()}

  @type get_institutions_response :: {:ok, GetInstitutionsResponse.t()} | {:error, any()}
  @callback get_institutions(access_token :: String.t(), country :: String.t()) ::
              {:ok, GetInstitutionsResponse.t()} | {:error, any()}
end

defmodule Gocardless.GocardlessApiImpl do
  alias Gocardless.GocardlessApi.RefreshTokenResponse
  alias Gocardless.GocardlessApi.GetInstitutionsResponse
  alias Gocardless.GocardlessApi.GetAccessTokenResponse
  @behaviour Gocardless.GocardlessApi

  def get_access_token(secret_id, secret_key) do
    "/token/new/"
    |> build_request(
      method: :post,
      body: %{
        secret_id: secret_id,
        secret_key: secret_key
      }
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
      headers: [{"Content-Type", "application/json"}],
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

  defp build_request(path, opts) do
    request_url = "https://bankaccountdata.gocardless.com/api/v2#{path}"

    body =
      if opts[:body] do
        Jason.encode!(opts[:body])
      else
        nil
      end

    headers = opts[:headers] || [{"Accept", "application/json"}]

    headers =
      if opts[:body] do
        [{"Content-Type", "application/json"} | headers]
      else
        headers
      end

    IO.inspect(headers, label: "Headers")
    IO.inspect(body, label: "Body")

    Finch.build(
      opts[:method] || :get,
      request_url,
      headers,
      body
    )
  end

  defp parse_as_json({:ok, %Finch.Response{status: 200, body: body}}) do
    Jason.decode(body)
  end

  defp parse_as_json({:ok, %Finch.Response{status: error_code, body: body, headers: headers}}) do
    {:error, {:http, error_code, body, headers}}
  end

  defp parse_as_json({:error, _exception} = error), do: error
end

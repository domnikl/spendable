defmodule Gocardless.GocardlessApi do
  use Knigge, otp_app: :spendable, default: Gocardless.GocardlessApiImpl

  # 1. add an alias for the response module
  alias __MODULE__.GetAccessTokenResponse

  @type get_access_token_response :: {:ok, GetAccessTokenResponse.t()} | {:error, any()}
  @callback get_access_token(secret_id :: String.t(), secret_key :: String.t()) ::
              get_access_token_response()
end

defmodule Gocardless.GocardlessApiImpl do
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

  defp build_request(path, opts) do
    # this is where authorization and/or other headers would be added
    # which are usually common among requests for a particular API
    request_url = "https://bankaccountdata.gocardless.com/api/v2#{path}"

    IO.inspect(request_url, label: "Request URL")
    IO.inspect(opts, label: "Request Options")

    Finch.build(
      opts[:method] || :get,
      request_url,
      [
        {"Content-Type", "application/json"}
      ],
      Jason.encode!(opts[:body] || %{})
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

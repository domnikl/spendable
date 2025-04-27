defmodule Gocardless.GocardlessApiTest do
  use ExUnit.Case, async: true
  import Mox

  alias Gocardless.GocardlessApi

  # This will ensure all expected mocks have been verified by the time each test is done.
  # See the Mox documentation https://hexdocs.pm/mox/Mox.html for nuances.
  setup :verify_on_exit!

  test "get_access_token returns access token and more" do
    MockGocardlessApi
    |> expect(:get_access_token, fn _, _ -> "hello from mock" end)

    # make sure that the interception works as expected (sanity check)
    # If we got it wrong we will get back "hello", not "hello from mock"
    assert "hello from mock" == GocardlessApi.get_access_token("secret_id", "secret_key")
  end
end

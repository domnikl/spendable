defmodule Gocardless.GocardlessApi.GetAccessTokenResponseTest do
  use ExUnit.Case, async: true

  alias Gocardless.GocardlessApi.GetAccessTokenResponse

  @valid_json_response %{"access" => "foobar", "some_ignored_key" => "foo"}

  describe("new/1") do
    test "can parse a valid json response" do
      assert %{
               access: "foobar",
               access_expires: nil,
               refresh: nil,
               refresh_expires: nil
             } = GetAccessTokenResponse.new(@valid_json_response)
    end
  end
end

defmodule Spendable.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spendable.Accounts` context.
  """

  import Spendable.UsersFixtures

  @doc """
  Generate an account.
  """
  def account_fixture(attrs \\ %{}) do
    user = if attrs[:user_id], do: nil, else: user_fixture()
    
    account_attrs = 
      attrs
      |> Enum.into(%{
        account_id: "test-account-#{System.unique_integer()}",
        iban: "DE89370400440532013000", 
        bic: "COBADEFFXXX",
        owner_name: "Test Owner",
        product: "Test Account",
        currency: "EUR",
        type: :manual,
        user_id: user && user.id || attrs[:user_id]
      })

    %Spendable.Accounts.Account{}
    |> struct(account_attrs)
    |> Spendable.Repo.insert!()
  end
end
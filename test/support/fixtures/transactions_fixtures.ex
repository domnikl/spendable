defmodule Spendable.TransactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spendable.Transactions` context.
  """

  import Spendable.UsersFixtures
  import Spendable.AccountsFixtures

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    # Create user and account if not provided
    user = if attrs[:user_id], do: nil, else: user_fixture()
    account = if attrs[:account_id], do: nil, else: account_fixture(%{user_id: user && user.id})

    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        amount: 42,
        booking_date: ~D[2025-05-04],
        counter_iban: "some counter_iban",
        counter_name: "some counter_name",
        currency: "some currency",
        purpose_code: "some purpose_code",
        transaction_id: "some transaction_id",
        value_date: ~D[2025-05-04],
        finalized: false,
        finalized_amount: 0,
        user_id: user && user.id,
        account_id: account && account.id
      })
      |> Spendable.Transactions.create_transaction()

    transaction
  end
end

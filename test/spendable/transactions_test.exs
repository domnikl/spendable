defmodule Spendable.TransactionsTest do
  use Spendable.DataCase

  alias Spendable.Transactions

  describe "transactions" do
    alias Spendable.Transactions.Transaction

    import Spendable.TransactionsFixtures
    import Spendable.UsersFixtures
    import Spendable.AccountsFixtures

    @invalid_attrs %{
      currency: nil,
      transaction_id: nil,
      counter_name: nil,
      counter_iban: nil,
      amount: nil,
      booking_date: nil,
      value_date: nil,
      purpose_code: nil,
      user_id: nil,
      account_id: nil
    }

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      [listed_transaction] = Transactions.list_transactions()
      assert listed_transaction.id == transaction.id
      assert listed_transaction.currency == transaction.currency
      assert listed_transaction.transaction_id == transaction.transaction_id
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Transactions.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      user = user_fixture()
      account = account_fixture(%{user_id: user.id})

      valid_attrs = %{
        currency: "some currency",
        transaction_id: "some transaction_id",
        counter_name: "some counter_name",
        counter_iban: "some counter_iban",
        amount: 42,
        booking_date: ~D[2025-05-04],
        value_date: ~D[2025-05-04],
        purpose_code: "some purpose_code",
        finalized: false,
        finalized_amount: 0,
        user_id: user.id,
        account_id: account.id
      }

      assert {:ok, %Transaction{} = transaction} = Transactions.create_transaction(valid_attrs)
      assert transaction.currency == "some currency"
      assert transaction.transaction_id == "some transaction_id"
      assert transaction.counter_name == "some counter_name"
      assert transaction.counter_iban == "some counter_iban"
      assert transaction.amount == 42
      assert transaction.booking_date == ~D[2025-05-04]
      assert transaction.value_date == ~D[2025-05-04]
      assert transaction.purpose_code == "some purpose_code"
      assert transaction.finalized == false
      assert transaction.finalized_amount == 0
      assert transaction.user_id == user.id
      assert transaction.account_id == account.id
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()

      update_attrs = %{
        currency: "some updated currency",
        transaction_id: "some updated transaction_id",
        counter_name: "some updated counter_name",
        counter_iban: "some updated counter_iban",
        amount: 43,
        booking_date: ~D[2025-05-05],
        value_date: ~D[2025-05-05],
        purpose_code: "some updated purpose_code"
      }

      assert {:ok, %Transaction{} = transaction} =
               Transactions.update_transaction(transaction, update_attrs)

      assert transaction.currency == "some updated currency"
      assert transaction.transaction_id == "some updated transaction_id"
      assert transaction.counter_name == "some updated counter_name"
      assert transaction.counter_iban == "some updated counter_iban"
      assert transaction.amount == 43
      assert transaction.booking_date == ~D[2025-05-05]
      assert transaction.value_date == ~D[2025-05-05]
      assert transaction.purpose_code == "some updated purpose_code"
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Transactions.update_transaction(transaction, @invalid_attrs)

      assert transaction == Transactions.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Transactions.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Transactions.change_transaction(transaction)
    end
  end
end

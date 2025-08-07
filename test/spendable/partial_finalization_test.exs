defmodule Spendable.PartialFinalizationTest do
  use Spendable.DataCase

  alias Spendable.{Transactions, Payments}
  alias Spendable.Transactions.Transaction

  import Spendable.UsersFixtures

  describe "partial transaction finalization" do
    setup do
      user = user_fixture()

      # Create account
      account =
        %Spendable.Accounts.Account{
          account_id: "test-account-123",
          iban: "DE89370400440532013000",
          bic: "COBADEFFXXX",
          owner_name: "Test Owner",
          product: "Test Account",
          currency: "EUR",
          type: :manual,
          user_id: user.id
        }
        |> Repo.insert!()

      # Create budget
      budget =
        %Spendable.Budgets.Budget{
          name: "Test Budget",
          # 1000.00 EUR
          amount: 100_000,
          due_date: Date.add(Date.utc_today(), 30),
          interval: :monthly,
          account_id: account.id,
          user_id: user.id,
          active: true,
          valid_start_date: Date.utc_today()
        }
        |> Repo.insert!()

      # Create transaction with 10000 cents (100.00 EUR)
      transaction =
        %Transaction{
          transaction_id: "TEST-001",
          counter_name: "Test Counter",
          counter_iban: "DE12345678901234567890",
          amount: 10000,
          currency: "EUR",
          booking_date: Date.utc_today(),
          value_date: Date.utc_today(),
          purpose_code: "OTHR",
          finalized: false,
          finalized_amount: 0,
          user_id: user.id,
          account_id: account.id
        }
        |> Repo.insert!()

      %{user: user, account: account, budget: budget, transaction: transaction}
    end

    test "transaction starts with zero finalized amount", %{transaction: transaction} do
      assert transaction.finalized_amount == 0
      assert transaction.finalized == false
      assert Transactions.get_remaining_amount(transaction) == 10000
    end

    test "creating payment updates finalized amount", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Create payment for 6000 cents (60.00 EUR)
      payment_attrs = %{
        "amount" => 6000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-001",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      {:ok, _payment} = Payments.create_payment_from_transaction(user, transaction, payment_attrs)

      # Check transaction is partially finalized
      updated_transaction = Transactions.get_transaction!(transaction.id)
      assert updated_transaction.finalized_amount == 6000
      # Not fully finalized yet
      assert updated_transaction.finalized == false
      assert Transactions.get_remaining_amount(updated_transaction) == 4000
    end

    test "creating second payment that completes transaction", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Create first payment for 6000 cents
      payment_attrs_1 = %{
        "amount" => 6000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-001",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      {:ok, _payment1} =
        Payments.create_payment_from_transaction(user, transaction, payment_attrs_1)

      # Create second payment for remaining 4000 cents
      updated_transaction = Transactions.get_transaction!(transaction.id)

      payment_attrs_2 = %{
        "amount" => 4000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-002",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      {:ok, _payment2} =
        Payments.create_payment_from_transaction(user, updated_transaction, payment_attrs_2)

      # Check transaction is now fully finalized
      final_transaction = Transactions.get_transaction!(transaction.id)
      assert final_transaction.finalized_amount == 10000
      assert final_transaction.finalized == true
      assert Transactions.get_remaining_amount(final_transaction) == 0
    end

    test "prevents payment that exceeds remaining amount", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Create first payment for 6000 cents
      payment_attrs_1 = %{
        "amount" => 6000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-001",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      {:ok, _payment1} =
        Payments.create_payment_from_transaction(user, transaction, payment_attrs_1)

      # Try to create payment for 5000 cents (would exceed remaining 4000)
      updated_transaction = Transactions.get_transaction!(transaction.id)

      payment_attrs_2 = %{
        "amount" => 5000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-002",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      # Should fail
      assert {:error, :exceeds_remaining_amount} =
               Payments.create_payment_from_transaction(
                 user,
                 updated_transaction,
                 payment_attrs_2
               )

      # Transaction should remain unchanged
      final_transaction = Transactions.get_transaction!(transaction.id)
      assert final_transaction.finalized_amount == 6000
      assert final_transaction.finalized == false
    end

    test "unfinalized transactions query includes partially finalized transactions", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Initially, transaction should appear in unfinalized list
      unfinalized = Transactions.list_unfinalized_transactions(user)
      assert length(unfinalized) == 1
      assert hd(unfinalized).id == transaction.id
      assert hd(unfinalized).remaining_amount == 10000

      # Create partial payment
      payment_attrs = %{
        "amount" => 6000,
        "budget_id" => budget.id,
        "payment_id" => "PAY-001",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => transaction.booking_date,
        "value_date" => transaction.value_date,
        "purpose_code" => transaction.purpose_code
      }

      {:ok, _payment} = Payments.create_payment_from_transaction(user, transaction, payment_attrs)

      # Should still appear in unfinalized list with remaining amount
      unfinalized = Transactions.list_unfinalized_transactions(user)
      assert length(unfinalized) == 1
      transaction_with_remaining = hd(unfinalized)
      assert transaction_with_remaining.id == transaction.id
      assert transaction_with_remaining.remaining_amount == 4000
    end
  end
end

defmodule Spendable.PaymentUIFixTest do
  use Spendable.DataCase

  alias Spendable.{Transactions, Payments}
  alias Spendable.Transactions.Transaction

  import Spendable.UsersFixtures

  describe "payment form data type handling" do
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

      # Create negative transaction (expense) - this is typical
      transaction =
        %Transaction{
          transaction_id: "TEST-001",
          counter_name: "Test Counter",
          counter_iban: "DE12345678901234567890",
          # Negative amount (expense)
          amount: -10000,
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

    test "handles string payment amounts from form", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Simulate form data (strings from HTML forms)
      payment_attrs = %{
        # String from HTML form
        "amount" => "6000",
        "budget_id" => Integer.to_string(budget.id),
        "payment_id" => "PAY-001",
        "counter_name" => transaction.counter_name,
        "counter_iban" => transaction.counter_iban,
        "currency" => transaction.currency,
        "booking_date" => Date.to_string(transaction.booking_date),
        "value_date" => Date.to_string(transaction.value_date),
        "purpose_code" => transaction.purpose_code
      }

      # Should work without error
      assert {:ok, _payment} =
               Payments.create_payment_from_transaction(user, transaction, payment_attrs)
    end

    test "handles integer payment amounts", %{
      user: user,
      transaction: transaction,
      budget: budget
    } do
      # Simulate programmatic data (integers)
      payment_attrs = %{
        # Integer
        amount: 6000,
        budget_id: budget.id,
        payment_id: "PAY-001",
        counter_name: transaction.counter_name,
        counter_iban: transaction.counter_iban,
        currency: transaction.currency,
        booking_date: transaction.booking_date,
        value_date: transaction.value_date,
        purpose_code: transaction.purpose_code
      }

      # Should work without error
      assert {:ok, _payment} =
               Payments.create_payment_from_transaction(user, transaction, payment_attrs)
    end

    test "correctly calculates remaining amount for negative transactions", %{
      transaction: transaction
    } do
      # For negative transaction amounts (expenses), remaining should be negative
      assert Transactions.get_remaining_amount(transaction) == -10000

      # Add remaining amount field
      transaction_with_remaining = Transactions.add_remaining_amount(transaction)
      assert transaction_with_remaining.remaining_amount == -10000
    end

    test "would_exceed_remaining_amount works with negative transactions", %{
      transaction: transaction
    } do
      # Should not exceed for valid amounts
      # String
      refute Transactions.would_exceed_remaining_amount?(transaction, "5000")
      # Integer
      refute Transactions.would_exceed_remaining_amount?(transaction, 5000)
      # String exact
      refute Transactions.would_exceed_remaining_amount?(transaction, "10000")

      # Should exceed for amounts larger than remaining
      # String
      assert Transactions.would_exceed_remaining_amount?(transaction, "15000")
      # Integer
      assert Transactions.would_exceed_remaining_amount?(transaction, 15000)
    end

    test "query for unfinalized transactions includes negative amounts", %{
      user: user,
      transaction: transaction
    } do
      unfinalized = Transactions.list_unfinalized_transactions(user)
      assert length(unfinalized) == 1
      found_transaction = hd(unfinalized)
      assert found_transaction.id == transaction.id
      assert found_transaction.remaining_amount == -10000
    end
  end
end

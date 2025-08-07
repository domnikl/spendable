defmodule Spendable.Accounts.AccountBalanceTest do
  use Spendable.DataCase

  alias Spendable.Accounts
  alias Spendable.Accounts.AccountBalance

  describe "changeset/2" do
    test "validates required fields" do
      changeset = AccountBalance.changeset(%AccountBalance{}, %{})

      assert %{
               account_id: ["can't be blank"],
               balance_date: ["can't be blank"],
               amount: ["can't be blank"],
               currency: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "creates valid changeset with proper attributes" do
      attrs = %{
        account_id: 1,
        balance_date: ~D[2025-01-01],
        # 100.50 in cents
        amount: 10050,
        currency: "EUR"
      }

      changeset = AccountBalance.changeset(%AccountBalance{}, attrs)
      assert changeset.valid?
    end
  end

  describe "convert_to_cents/1" do
    test "converts decimal amounts to cents" do
      assert Accounts.convert_to_cents(Decimal.new("10.50")) == 1050
      assert Accounts.convert_to_cents(Decimal.new("100.00")) == 10000
      assert Accounts.convert_to_cents(Decimal.new("0.01")) == 1
      assert Accounts.convert_to_cents(Decimal.new("0.00")) == 0
    end

    test "converts string amounts to cents" do
      assert Accounts.convert_to_cents("10.50") == 1050
      assert Accounts.convert_to_cents("100.00") == 10000
      assert Accounts.convert_to_cents("0.01") == 1
      assert Accounts.convert_to_cents("0.00") == 0
    end
  end
end

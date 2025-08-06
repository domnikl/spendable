defmodule Spendable.AccountsListWithBalancesTest do
  use Spendable.DataCase

  alias Spendable.Accounts
  alias Spendable.Accounts.{Account, AccountBalance}
  
  import Spendable.UsersFixtures

  describe "list_accounts/1 with balances" do
    test "returns accounts with latest balance when balance exists" do
      user = user_fixture()
      
      # Create an account directly
      account = Repo.insert!(%Account{
        account_id: "test-account-123",
        iban: "DE89370400440532013000",
        bic: "COBADEFFXXX",
        owner_name: "Test Owner",
        product: "Test Product",
        currency: "EUR",
        type: :manual,
        user_id: user.id
      })
      
      # Create balance entries
      _older_balance = %AccountBalance{
        account_id: account.id,
        balance_date: ~D[2025-01-01],
        amount: 50000,  # 500.00 EUR in cents
        currency: "EUR"
      } |> Repo.insert!()
      
      latest_balance = %AccountBalance{
        account_id: account.id,
        balance_date: ~D[2025-01-02],
        amount: 75000,  # 750.00 EUR in cents
        currency: "EUR"
      } |> Repo.insert!()
      
      # List accounts should include the latest balance
      accounts = Accounts.list_accounts(user)
      
      assert length(accounts) == 1
      account_with_balance = List.first(accounts)
      
      assert account_with_balance.latest_balance != nil
      assert account_with_balance.latest_balance.id == latest_balance.id
      assert account_with_balance.latest_balance.amount == 75000
      assert account_with_balance.latest_balance.balance_date == ~D[2025-01-02]
    end

    test "returns accounts with nil latest_balance when no balance exists" do
      user = user_fixture()
      
      # Create an account without any balance directly
      _account = Repo.insert!(%Account{
        account_id: "test-account-456",
        iban: "DE89370400440532013001",
        bic: "COBADEFFXXX",
        owner_name: "Test Owner 2",
        product: "Test Product 2",
        currency: "EUR",
        type: :manual,
        user_id: user.id
      })
      
      # List accounts should have nil latest_balance
      accounts = Accounts.list_accounts(user)
      
      assert length(accounts) == 1
      account_with_balance = List.first(accounts)
      
      assert account_with_balance.latest_balance == nil
    end
  end
end
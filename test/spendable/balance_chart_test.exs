defmodule Spendable.BalanceChartTest do
  use Spendable.DataCase

  alias Spendable.{Accounts, Users}
  
  import Spendable.UsersFixtures
  import Spendable.AccountsFixtures

  describe "balance chart functionality" do
    setup do
      user = user_fixture()
      account = account_fixture(%{user_id: user.id})

      # Create some balance data
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      last_week = Date.add(today, -7)

      {:ok, _} = Accounts.upsert_account_balance(account, yesterday, 150000, "EUR")  # 1500.00 EUR
      {:ok, _} = Accounts.upsert_account_balance(account, last_week, 200000, "EUR")   # 2000.00 EUR
      {:ok, _} = Accounts.upsert_account_balance(account, today, 175000, "EUR")       # 1750.00 EUR

      %{user: user, account: account}
    end

    test "get_balance_chart_data returns properly formatted data", %{account: account} do
      chart_data = Accounts.get_balance_chart_data(account.id)
      
      # Should be a map with month keys
      assert is_map(chart_data)
      
      # Should have current month data
      current_month = Date.utc_today() |> Date.to_string() |> String.slice(0, 7)
      current_month_data = Map.get(chart_data, current_month, %{})
      
      # Should have some data for current month
      assert map_size(current_month_data) > 0
      
      # Values should be in euros (converted from cents)
      for {_day, amount} <- current_month_data do
        assert is_number(amount)
        assert amount >= 0  # Should be positive euros
      end
    end

    test "get_chart_months returns 12 months" do
      months = Accounts.get_chart_months()
      
      assert length(months) == 12
      
      # Should be in YYYY-MM format
      for month <- months do
        assert String.match?(month, ~r/^\d{4}-\d{2}$/)
      end
      
      # Should be in chronological order (oldest first)
      assert months == Enum.sort(months)
    end

    test "chart data conversion handles cents to euros properly", %{account: account} do
      # Create balance with known amount
      test_date = Date.utc_today()
      {:ok, _} = Accounts.upsert_account_balance(account, test_date, 123456, "EUR")  # 1234.56 EUR
      
      chart_data = Accounts.get_balance_chart_data(account.id)
      current_month = test_date |> Date.to_string() |> String.slice(0, 7)
      current_month_data = Map.get(chart_data, current_month, %{})
      
      # Should convert 123456 cents to 1235 euros (rounded)
      day_amount = Map.get(current_month_data, test_date.day)
      assert day_amount == 1235.0  # Float.round(123456 / 100.0)
    end
  end

  describe "user preferences" do
    test "can update preferred chart account", do
      user = user_fixture()
      account = account_fixture(%{user_id: user.id})

      assert user.preferred_chart_account_id == nil

      {:ok, updated_user} = Users.update_user_preferences(user, %{preferred_chart_account_id: account.id})
      assert updated_user.preferred_chart_account_id == account.id
    end
  end
end
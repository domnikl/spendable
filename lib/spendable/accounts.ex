defmodule Spendable.Accounts do
  alias Spendable.Repo
  alias Spendable.Accounts.Account
  alias Spendable.Accounts.AccountBalance

  import Ecto.Query, warn: false

  def upsert_account(user, requisition, attrs) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:requisition, requisition)
    |> Repo.insert(
      on_conflict: [set: [owner_name: attrs.owner_name, currency: attrs.currency]],
      conflict_target: :account_id
    )
  end

  def active_gocardless_accounts() do
    Repo.all(
      from a in Account,
        where: a.active == true,
        where: a.type == ^:gocardless,
        order_by: [desc: a.id]
    )
    |> Repo.preload(:user)
  end

  def list_accounts(user) do
    accounts =
      Repo.all(
        from a in Account,
          where: a.user_id == ^user.id,
          order_by: [desc: a.id]
      )

    # Add latest balance to each account
    Enum.map(accounts, fn account ->
      latest_balance = get_latest_balance(account)
      Map.put(account, :latest_balance, latest_balance)
    end)
  end

  def get_account!(user, account_id) do
    Repo.get_by!(Account, user_id: user.id, account_id: account_id)
  end

  def set_active_account(account, active) do
    account
    |> Account.active_changeset(%{active: active})
    |> Repo.update()
  end

  def upsert_account_balance(account, balance_date, amount_cents, currency) do
    attrs = %{
      account_id: account.id,
      balance_date: balance_date,
      amount: amount_cents,
      currency: currency
    }

    %AccountBalance{}
    |> AccountBalance.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:amount, :currency, :updated_at]},
      conflict_target: [:account_id, :balance_date]
    )
  end

  def get_latest_balance(account) do
    Repo.one(
      from ab in AccountBalance,
        where: ab.account_id == ^account.id,
        order_by: [desc: ab.balance_date],
        limit: 1
    )
  end

  def get_balance_for_date(account, date) do
    Repo.get_by(AccountBalance, account_id: account.id, balance_date: date)
  end

  def list_account_balances(account, limit \\ 30) do
    Repo.all(
      from ab in AccountBalance,
        where: ab.account_id == ^account.id,
        order_by: [desc: ab.balance_date],
        limit: ^limit
    )
  end

  @doc """
  Converts a decimal amount to cents (integer).
  Examples:
    convert_to_cents(Decimal.new("10.50")) -> 1050
    convert_to_cents(Decimal.new("100.00")) -> 10000
  """
  def convert_to_cents(%Decimal{} = decimal_amount) do
    decimal_amount
    |> Decimal.mult(100)
    |> Decimal.to_integer()
  end

  def convert_to_cents(string_amount) when is_binary(string_amount) do
    string_amount
    |> Decimal.new()
    |> convert_to_cents()
  end

  @doc """
  Gets balance data for chart display for the last 12 months.
  Returns a map with months as keys and daily balance data as values.

  Example return:
  %{
    "2024-12" => %{
      1 => 1500,  # Day 1: 15.00 EUR
      2 => 1450,  # Day 2: 14.50 EUR
      ...
      31 => 1200
    },
    "2025-01" => %{...}
  }
  """
  def get_balance_chart_data(account_id) do
    end_date = Date.utc_today()
    # Get 12 months of data
    start_date = Date.add(end_date, -365)

    balances =
      Repo.all(
        from ab in AccountBalance,
          where: ab.account_id == ^account_id,
          where: ab.balance_date >= ^start_date,
          where: ab.balance_date <= ^end_date,
          order_by: [asc: ab.balance_date]
      )

    # Group by month and organize by day
    balances
    |> Enum.group_by(fn balance ->
      date = balance.balance_date
      "#{date.year}-#{String.pad_leading(Integer.to_string(date.month), 2, "0")}"
    end)
    |> Map.new(fn {month, month_balances} ->
      daily_data =
        month_balances
        |> Enum.map(fn balance ->
          # Convert cents to euros and round
          euros = Float.round(balance.amount / 100.0)
          {balance.balance_date.day, euros}
        end)
        |> Map.new()

      {month, daily_data}
    end)
  end

  @doc """
  Gets the last 12 months in YYYY-MM format for chart display.
  """
  def get_chart_months() do
    today = Date.utc_today()

    0..11
    |> Enum.map(fn months_back ->
      # Approximate months
      date = Date.add(today, -months_back * 30)
      "#{date.year}-#{String.pad_leading(Integer.to_string(date.month), 2, "0")}"
    end)
    |> Enum.reverse()
  end
end

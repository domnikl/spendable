defmodule Spendable.Repo.Migrations.UpdateAccountBalancesAmountToInteger do
  use Ecto.Migration

  def up do
    alter table(:account_balances) do
      modify :amount, :bigint, null: false
    end
  end

  def down do
    alter table(:account_balances) do
      modify :amount, :decimal, precision: 15, scale: 2, null: false
    end
  end
end

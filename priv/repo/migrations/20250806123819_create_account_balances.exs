defmodule Spendable.Repo.Migrations.CreateAccountBalances do
  use Ecto.Migration

  def change do
    create table(:account_balances) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :balance_date, :date, null: false
      add :amount, :decimal, precision: 15, scale: 2, null: false
      add :currency, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:account_balances, [:account_id, :balance_date])
    create index(:account_balances, [:account_id])
    create index(:account_balances, [:balance_date])
  end
end

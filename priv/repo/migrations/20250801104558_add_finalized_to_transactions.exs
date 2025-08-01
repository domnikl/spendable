defmodule Spendable.Repo.Migrations.AddFinalizedToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :finalized, :boolean, default: false, null: false
    end

    create table(:payments) do
      add :payment_id, :string, null: false
      add :counter_name, :string, null: false
      add :counter_iban, :string, null: false
      add :amount, :integer, null: false
      add :currency, :string, null: false
      add :booking_date, :date, null: false
      add :value_date, :date, null: false
      add :purpose_code, :string, null: false
      add :description, :string
      add :transaction_id, references(:transactions, on_delete: :delete_all), null: false
      add :budget_id, references(:budgets, on_delete: :restrict), null: false
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:finalized])
    create index(:payments, [:user_id])
    create index(:payments, [:transaction_id])
    create index(:payments, [:budget_id])
    create index(:payments, [:account_id])
    create index(:payments, [:booking_date])
  end
end

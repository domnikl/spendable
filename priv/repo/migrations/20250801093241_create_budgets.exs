defmodule Spendable.Repo.Migrations.CreateBudgets do
  use Ecto.Migration

  def change do
    create table(:budgets) do
      add :name, :string, null: false
      add :amount, :integer, null: false
      add :due_date, :date, null: false
      add :interval, :string, null: false
      add :active, :boolean, default: true, null: false
      add :parent_id, references(:budgets, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :account_id, references(:accounts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:budgets, [:user_id])
    create index(:budgets, [:account_id])
    create index(:budgets, [:parent_id])
    create index(:budgets, [:active])
  end
end

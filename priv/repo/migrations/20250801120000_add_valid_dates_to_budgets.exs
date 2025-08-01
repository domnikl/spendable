defmodule Spendable.Repo.Migrations.AddValidDatesToBudgets do
  use Ecto.Migration

  def change do
    alter table(:budgets) do
      add :valid_start_date, :date, null: false, default: fragment("CURRENT_DATE")
      add :valid_end_date, :date, null: true
    end

    create index(:budgets, [:valid_start_date])
    create index(:budgets, [:valid_end_date])
  end
end

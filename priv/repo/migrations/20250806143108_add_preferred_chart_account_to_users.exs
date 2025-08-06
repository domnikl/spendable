defmodule Spendable.Repo.Migrations.AddPreferredChartAccountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :preferred_chart_account_id, references(:accounts, on_delete: :nilify_all), null: true
    end

    create index(:users, [:preferred_chart_account_id])
  end
end

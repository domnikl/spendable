defmodule Spendable.Repo.Migrations.AddRequisitionToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :requisition_id, :string, null: true, default: nil
    end

    create index(:users, [:requisition_id])
  end
end

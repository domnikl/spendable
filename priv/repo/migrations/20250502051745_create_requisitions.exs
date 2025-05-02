defmodule Spendable.Repo.Migrations.CreateRequisitions do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :requisition_id
    end

    create table(:requisitions) do
      add :requisition_id, :string, null: false
      add :institution_id, :string, null: false
      add :name, :string, null: false
      add :reference, :string, null: false
      add :active, :boolean, null: false, default: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:requisitions, [:user_id])
    create unique_index(:requisitions, [:requisition_id])
    create unique_index(:requisitions, [:institution_id, :user_id])
  end

  def down do
    drop table(:requisitions)

    alter table(:users) do
      add :requisition_id, :string, null: true, default: nil
    end

    create index(:users, [:requisition_id])
  end
end

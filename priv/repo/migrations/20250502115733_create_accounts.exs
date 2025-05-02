defmodule Spendable.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :account_id, :string
      add :type, :string
      add :iban, :string
      add :bic, :string
      add :owner_name, :string
      add :product, :string
      add :balance, :integer
      add :currency, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :requisition_id, references(:requisitions, on_delete: :delete_all), null: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:account_id])
  end
end

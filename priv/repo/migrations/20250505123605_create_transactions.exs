defmodule Spendable.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :transaction_id, :string
      add :counter_name, :string
      add :counter_iban, :string
      add :amount, :integer
      add :currency, :string
      add :booking_date, :date
      add :value_date, :date
      add :purpose_code, :string
      add :description, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :account_id, references(:accounts, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end

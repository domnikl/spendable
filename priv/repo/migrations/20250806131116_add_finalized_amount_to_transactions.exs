defmodule Spendable.Repo.Migrations.AddFinalizedAmountToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :finalized_amount, :bigint, default: 0, null: false
    end

    # Create index for better query performance
    create index(:transactions, [:finalized_amount])
  end
end

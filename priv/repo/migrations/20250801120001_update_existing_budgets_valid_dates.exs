defmodule Spendable.Repo.Migrations.UpdateExistingBudgetsValidDates do
  use Ecto.Migration

  def up do
    # Update existing budgets to have valid_start_date set to their created_at date
    # and valid_end_date set to null (meaning they are active)
    execute """
    UPDATE budgets
    SET valid_start_date = DATE(inserted_at),
        valid_end_date = NULL
    WHERE valid_start_date IS NULL
    """
  end

  def down do
    # This migration only sets data, so down is a no-op
  end
end

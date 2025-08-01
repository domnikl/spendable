defmodule Spendable.Budgets do
  alias Spendable.Repo
  alias Spendable.Budgets.Budget

  import Ecto.Query, warn: false

  def list_budgets(user) do
    budgets =
      Repo.all(
        from b in Budget,
          where: b.user_id == ^user.id,
          order_by: [desc: b.id],
          preload: [:account, :parent, :children]
      )

    # Calculate usage for each budget
    Enum.map(budgets, &calculate_budget_usage/1)
  end

  def list_active_budgets(user) do
    budgets =
      Repo.all(
        from b in Budget,
          where: b.user_id == ^user.id,
          where: b.active == true,
          order_by: [desc: b.id],
          preload: [:account, :parent, :children]
      )

    # Calculate usage for each budget
    Enum.map(budgets, &calculate_budget_usage/1)
  end

  def get_budget!(user, budget_id) do
    Repo.get_by!(Budget, user_id: user.id, id: budget_id)
    |> Repo.preload([:account, :parent, :children])
  end

  def create_budget(user, attrs) do
    %Budget{}
    |> Budget.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def change_budget(%Budget{} = budget, attrs \\ %{}) do
    Budget.update_changeset(budget, attrs)
  end

  def update_budget(budget, attrs) do
    budget
    |> Budget.update_changeset(attrs)
    |> Repo.update()
  end

  def set_active_budget(budget, active) do
    budget
    |> Budget.active_changeset(%{active: active})
    |> Repo.update()
  end

  def delete_budget(budget) do
    Repo.delete(budget)
  end

  def get_parent_budgets(user) do
    Repo.all(
      from b in Budget,
        where: b.user_id == ^user.id,
        where: is_nil(b.parent_id),
        order_by: [asc: b.name]
    )
  end

  def get_child_budgets(budget) do
    Repo.all(
      from b in Budget,
        where: b.parent_id == ^budget.id,
        order_by: [asc: b.name]
    )
  end

  defp calculate_budget_usage(budget) do
    # Get all payments for this budget
    payments =
      Repo.all(
        from p in Spendable.Payments.Payment,
          where: p.budget_id == ^budget.id,
          select: sum(p.amount)
      )

    total_used =
      case payments do
        [nil] -> 0
        [amount] -> amount
        _ -> 0
      end

    # Calculate percentage for negative budgets
    percentage =
      if budget.amount < 0 do
        abs(total_used) / abs(budget.amount) * 100
      else
        nil
      end

    # Add usage info to budget
    budget
    |> Map.put(:total_used, total_used)
    |> Map.put(:percentage_used, percentage)
  end
end

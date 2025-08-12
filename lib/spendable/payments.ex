defmodule Spendable.Payments do
  alias Spendable.Repo
  alias Spendable.Payments.Payment
  alias Spendable.Transactions

  import Ecto.Query, warn: false

  def list_payments(user, page \\ 1, per_page \\ 25, filters \\ %{}) do
    offset = (page - 1) * per_page

    base_query =
      from p in Payment,
        where: p.user_id == ^user.id,
        order_by: [desc: p.booking_date],
        preload: [:transaction, :budget, :account]

    query = apply_filters(base_query, filters)

    # Add pagination
    paginated_query =
      from p in query,
        limit: ^per_page,
        offset: ^offset

    payments = Repo.all(paginated_query)

    # Get total count with filters applied
    count_query =
      apply_filters(
        from(p in Payment, where: p.user_id == ^user.id, select: count(p.id)),
        filters
      )

    total_count = Repo.one(count_query)

    %{
      payments: payments,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: ceil(total_count / per_page)
    }
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      apply_filter(acc, key, value)
    end)
  end

  defp apply_filter(query, :account_id, nil), do: query

  defp apply_filter(query, :account_id, account_id) do
    from p in query, where: p.account_id == ^account_id
  end

  defp apply_filter(query, :budget_id, nil), do: query

  defp apply_filter(query, :budget_id, budget_id) do
    from p in query, where: p.budget_id == ^budget_id
  end

  defp apply_filter(query, :date_from, nil), do: query

  defp apply_filter(query, :date_from, date_from) do
    from p in query, where: p.booking_date >= ^date_from
  end

  defp apply_filter(query, :date_to, nil), do: query

  defp apply_filter(query, :date_to, date_to) do
    from p in query, where: p.booking_date <= ^date_to
  end

  defp apply_filter(query, :search, nil), do: query
  defp apply_filter(query, :search, ""), do: query

  defp apply_filter(query, :search, search_term) do
    search_pattern = "%#{search_term}%"

    from p in query,
      where: ilike(p.counter_name, ^search_pattern) or ilike(p.description, ^search_pattern)
  end

  defp apply_filter(query, :amount_min, nil), do: query

  defp apply_filter(query, :amount_min, amount_min) do
    from p in query, where: p.amount >= ^amount_min
  end

  defp apply_filter(query, :amount_max, nil), do: query

  defp apply_filter(query, :amount_max, amount_max) do
    from p in query, where: p.amount <= ^amount_max
  end

  defp apply_filter(query, _key, _value), do: query

  def list_recent_payments(user, limit \\ 10) do
    Repo.all(
      from p in Payment,
        where: p.user_id == ^user.id,
        order_by: [desc: p.booking_date],
        limit: ^limit,
        preload: [:transaction, :budget, :account]
    )
  end

  def get_payment!(user, payment_id) do
    Repo.get_by!(Payment, user_id: user.id, id: payment_id)
    |> Repo.preload([:transaction, :budget, :account])
  end

  def create_payment(user, attrs) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def create_payment_from_transaction(user, transaction, attrs) do
    # Check if payment amount would exceed remaining transaction amount
    payment_amount = Map.get(attrs, "amount") || Map.get(attrs, :amount)

    if payment_amount && Transactions.would_exceed_remaining_amount?(transaction, payment_amount) do
      {:error, :exceeds_remaining_amount}
    else
      Repo.transaction(fn ->
        # Create the payment
        case %Payment{}
             |> Payment.create_from_transaction_changeset(transaction, attrs)
             |> Ecto.Changeset.put_assoc(:user, user)
             |> Repo.insert() do
          {:ok, payment} ->
            # Update the transaction's finalized amount
            case Transactions.add_finalized_amount(transaction, payment.amount) do
              {:ok, _updated_transaction} ->
                payment

              {:error, changeset} ->
                Repo.rollback(changeset)
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  def update_payment(payment, attrs) do
    payment
    |> Payment.changeset(attrs)
    |> Repo.update()
  end

  def delete_payment(payment) do
    Repo.delete(payment)
  end

  def change_payment(%Payment{} = payment, attrs \\ %{}) do
    Payment.changeset(payment, attrs)
  end

  def change_payment_from_transaction(%Payment{} = payment, transaction, attrs \\ %{}) do
    Payment.create_from_transaction_changeset(payment, transaction, attrs)
  end
end

defmodule Spendable.Payments do
  alias Spendable.Repo
  alias Spendable.Payments.Payment
  alias Spendable.Transactions

  import Ecto.Query, warn: false

  def list_payments(user) do
    Repo.all(
      from p in Payment,
        where: p.user_id == ^user.id,
        order_by: [desc: p.booking_date],
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

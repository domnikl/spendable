defmodule Spendable.Payments do
  alias Spendable.Repo
  alias Spendable.Payments.Payment

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
    %Payment{}
    |> Payment.create_from_transaction_changeset(transaction, attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
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

defmodule Spendable.Payments.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    field :currency, :string
    field :payment_id, :string
    field :counter_name, :string
    field :counter_iban, :string
    field :amount, :integer
    field :booking_date, :date
    field :value_date, :date
    field :purpose_code, :string
    field :description, :string

    belongs_to :transaction, Spendable.Transactions.Transaction
    belongs_to :budget, Spendable.Budgets.Budget
    belongs_to :account, Spendable.Accounts.Account
    belongs_to :user, Spendable.Users.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
      :payment_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :description,
      :transaction_id,
      :budget_id,
      :account_id,
      :user_id
    ])
    |> validate_required([
      :payment_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :transaction_id,
      :budget_id,
      :account_id,
      :user_id
    ])
    |> validate_number(:amount, greater_than: 0)
  end

  def create_from_transaction_changeset(payment, transaction, attrs) do
    payment
    |> cast(attrs, [
      :payment_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :description,
      :budget_id
    ])
    |> put_change(:transaction_id, transaction.id)
    |> put_change(:account_id, transaction.account_id)
    |> put_change(:user_id, transaction.user_id)
    |> validate_required([
      :payment_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :budget_id
    ])
    |> validate_number(:amount, greater_than: 0)
  end
end

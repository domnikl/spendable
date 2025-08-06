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
    |> validate_number(:amount, greater_than: -999_999_999)
  end

  def create_from_transaction_changeset(payment, transaction, attrs) do
    payment
    |> cast(attrs, [
      :amount,
      :booking_date,
      :description,
      :budget_id
    ])
    |> put_change(:transaction_id, transaction.id)
    |> put_change(:account_id, transaction.account_id)
    |> put_change(:user_id, transaction.user_id)
    |> put_change(:payment_id, "PAY-#{transaction.transaction_id}")
    |> put_change(:counter_name, transaction.counter_name)
    |> put_change(:counter_iban, transaction.counter_iban)
    |> put_change(:currency, transaction.currency)
    |> put_change(:value_date, transaction.value_date)
    |> put_change(:purpose_code, transaction.purpose_code)
    |> validate_required([
      :amount,
      :booking_date,
      :budget_id
    ])
    |> validate_number(:amount, greater_than: -999_999_999)
  end
end

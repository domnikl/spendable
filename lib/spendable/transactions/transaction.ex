defmodule Spendable.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :currency, :string
    field :transaction_id, :string
    field :counter_name, :string
    field :counter_iban, :string
    field :amount, :integer
    field :booking_date, :date
    field :value_date, :date
    field :purpose_code, :string
    field :description, :string
    field :finalized, :boolean, default: false

    belongs_to :account, Spendable.Accounts.Account
    belongs_to :user, Spendable.Users.User
    has_many :payments, Spendable.Payments.Payment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :transaction_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :description,
      :finalized,
      :user_id,
      :account_id
    ])
    |> validate_required([
      :transaction_id,
      :counter_name,
      :counter_iban,
      :amount,
      :currency,
      :booking_date,
      :value_date,
      :purpose_code,
      :user_id,
      :account_id
    ])
  end
end

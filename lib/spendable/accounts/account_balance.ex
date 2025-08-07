defmodule Spendable.Accounts.AccountBalance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "account_balances" do
    field :balance_date, :date
    field :amount, :integer
    field :currency, :string

    belongs_to :account, Spendable.Accounts.Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account_balance, attrs) do
    account_balance
    |> cast(attrs, [:account_id, :balance_date, :amount, :currency])
    |> validate_required([:account_id, :balance_date, :amount, :currency])
    |> unique_constraint([:account_id, :balance_date])
    |> foreign_key_constraint(:account_id)
  end
end

defmodule Spendable.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :account_id, :string
    field :type, Ecto.Enum, values: [:gocardless], default: :gocardless
    field :iban, :string
    field :bic, :string
    field :owner_name, :string
    field :product, :string
    field :balance, :integer
    field :currency, :string

    belongs_to :user, Spendable.Users.User
    belongs_to :requisition, Spendable.Requisitions.Requisition

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(account, attrs) do
    account
    |> cast(attrs, [:account_id, :iban, :bic, :owner_name, :product, :balance, :currency])
    |> validate_required([:account_id, :iban, :bic, :owner_name, :product, :currency])
  end
end

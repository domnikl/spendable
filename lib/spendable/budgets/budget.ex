defmodule Spendable.Budgets.Budget do
  use Ecto.Schema
  import Ecto.Changeset

  schema "budgets" do
    field :name, :string
    field :amount, :integer
    field :due_date, :date

    field :interval, Ecto.Enum,
      values: [:monthly, :quarterly, :yearly, :one_time],
      default: :monthly

    field :active, :boolean, default: true

    belongs_to :user, Spendable.Users.User
    belongs_to :account, Spendable.Accounts.Account
    belongs_to :parent, Spendable.Budgets.Budget
    has_many :children, Spendable.Budgets.Budget, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(budget, attrs) do
    budget
    |> cast(attrs, [:name, :amount, :due_date, :interval, :account_id, :parent_id])
    |> validate_required([:name, :amount, :due_date, :interval, :account_id])
    |> validate_number(:amount, greater_than: -999_999_999)
    |> validate_change(:due_date, fn :due_date, due_date ->
      if Date.compare(due_date, Date.utc_today()) in [:gt, :eq] do
        []
      else
        [due_date: "must be today or in the future"]
      end
    end)
  end

  def update_changeset(budget, attrs) do
    budget
    |> cast(attrs, [:name, :amount, :due_date, :interval, :account_id, :parent_id])
    |> validate_required([:name, :amount, :due_date, :interval, :account_id])
    |> validate_number(:amount, greater_than: -999_999_999)
    |> validate_change(:due_date, fn :due_date, due_date ->
      if Date.compare(due_date, Date.utc_today()) in [:gt, :eq] do
        []
      else
        [due_date: "must be today or in the future"]
      end
    end)
  end

  def active_changeset(budget, attrs) do
    budget
    |> cast(attrs, [:active])
    |> validate_required([:active])
  end
end

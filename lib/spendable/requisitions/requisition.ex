defmodule Spendable.Requisitions.Requisition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "requisitions" do
    field :requisition_id, :string
    field :institution_id, :string
    field :active, :boolean, default: false
    field :name, :string
    field :reference, :string

    belongs_to :user, Spendable.Users.User

    timestamps()
  end

  def create_changeset(requisition, attrs) do
    requisition
    |> cast(attrs, [:requisition_id, :institution_id, :name, :reference])
    |> validate_required([:requisition_id, :institution_id, :name, :reference])
    |> unique_constraint(:requisition_id, name: :requisitions_institution_id_user_id_index)
  end

  def verify_changeset(requisition, attr) do
    requisition
    |> cast(attr, [:active])
    |> validate_required([:active])
  end
end

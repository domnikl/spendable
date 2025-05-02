defmodule Spendable.Requisitions do
  alias Spendable.Repo
  alias Spendable.Requisitions.Requisition

  @doc """
  Create a requisition for a user.
  """

  def create_requisition(user, attrs) do
    %Requisition{}
    |> Requisition.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Get a requisition by its reference.
  """
  def get_by_reference(user, reference) do
    Repo.get_by(Requisition, user_id: user.id, reference: reference)
  end

  @doc """
  Verify a requisition by updating its active status.
  """
  def verify_requisition(requisition) do
    requisition
    |> Requisition.verify_changeset(%{active: true})
    |> Repo.update()
  end
end

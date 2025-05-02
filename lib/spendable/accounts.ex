defmodule Spendable.Accounts do
  alias Spendable.Repo
  alias Spendable.Accounts.Account

  def upsert_account(user, requisition, attrs) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:requisition, requisition)
    |> Repo.insert(
      on_conflict: [set: [owner_name: attrs.owner_name, currency: attrs.currency]],
      conflict_target: :account_id
    )
  end
end

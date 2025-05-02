defmodule Spendable.Accounts do
  alias Spendable.Repo
  alias Spendable.Accounts.Account

  import Ecto.Query, warn: false

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

  def list_accounts(user) do
    Repo.all(
      from a in Account,
        where: a.user_id == ^user.id,
        order_by: [desc: a.id]
    )
  end

  def get_account!(user, account_id) do
    Repo.get_by!(Account, user_id: user.id, account_id: account_id)
  end

  def set_active_account(account, active) do
    account
    |> Account.active_changeset(%{active: active})
    |> Repo.update()
  end
end

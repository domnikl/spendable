defmodule Spendable.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias Spendable.Accounts
  alias Gocardless.GocardlessApi.GetTransactionsResponse
  alias Spendable.Repo

  alias Spendable.Transactions.Transaction

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(
      from t in Transaction,
        order_by: [desc: t.booking_date]
    )
    |> Repo.preload(:account)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def import_transactions() do
    accounts = Accounts.active_gocardless_accounts()

    for account <- accounts do
      {:ok, transactions} = Gocardless.Client.get_transactions(account.account_id)

      transactions
      |> Enum.map(&map_transaction(&1, account))
      |> Enum.map(&create_transaction/1)
    end
  end

  defp map_transaction(transaction, account) do
    amount =
      transaction.transaction_amount.amount
      |> String.replace(".", "")
      |> String.to_integer()

    currency = transaction.transaction_amount.currency

    {name, iban} =
      if amount < 0 do
        {transaction.debtor_name, transaction.debtor_account.iban}
      else
        {transaction.creditor_name, transaction.creditor_account.iban}
      end

    %{
      transaction_id: transaction.internal_transaction_id,
      booking_date: transaction.booking_date,
      value_date: transaction.value_date,
      amount: amount,
      currency: currency,
      counter_name: name,
      counter_iban: iban,
      purpose_code: transaction.purpose_code,
      account_id: account.id,
      user_id: account.user_id
    }
  end
end

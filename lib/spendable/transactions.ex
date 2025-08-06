defmodule Spendable.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias Spendable.Accounts
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

  def list_unfinalized_transactions(user) do
    Repo.all(
      from t in Transaction,
        where: t.user_id == ^user.id,
        where:
          t.finalized == false or
            fragment("abs(?)", t.finalized_amount) < fragment("abs(?)", t.amount),
        order_by: [desc: t.booking_date]
    )
    |> Repo.preload(:account)
    |> Enum.map(&add_remaining_amount/1)
  end

  def set_transaction_finalized(transaction, finalized) do
    transaction
    |> Ecto.Changeset.change(%{finalized: finalized})
    |> Repo.update()
  end

  @doc """
  Adds the specified amount to the transaction's finalized_amount.
  Returns {:ok, transaction} or {:error, changeset} if validation fails.
  """
  def add_finalized_amount(transaction, payment_amount) do
    new_finalized_amount = transaction.finalized_amount + abs(payment_amount)

    # Check if this would fully finalize the transaction
    fully_finalized = abs(new_finalized_amount) >= abs(transaction.amount)

    transaction
    |> Transaction.changeset(%{
      finalized_amount: new_finalized_amount,
      finalized: fully_finalized
    })
    |> Repo.update()
  end

  @doc """
  Gets the remaining amount that can still be finalized for a transaction.
  Returns signed amount (negative for expenses, positive for income).
  """
  def get_remaining_amount(transaction) do
    remaining_abs = abs(transaction.amount) - abs(transaction.finalized_amount)
    if transaction.amount < 0, do: -remaining_abs, else: remaining_abs
  end

  @doc """
  Adds a virtual remaining_amount field to transaction struct.
  """
  def add_remaining_amount(transaction) do
    remaining = get_remaining_amount(transaction)
    Map.put(transaction, :remaining_amount, remaining)
  end

  @doc """
  Checks if the given payment amount would exceed the remaining transaction amount.
  """
  def would_exceed_remaining_amount?(transaction, payment_amount) do
    remaining = get_remaining_amount(transaction)

    # Handle both string and integer payment amounts
    amount_int =
      case payment_amount do
        amount when is_integer(amount) -> amount
        amount when is_binary(amount) -> String.to_integer(amount)
        _ -> 0
      end

    # Compare absolute values since both remaining and payment amounts maintain their signs
    abs(amount_int) > abs(remaining)
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
      description: transaction.remittance_information_unstructured,
      account_id: account.id,
      user_id: account.user_id
    }
  end
end

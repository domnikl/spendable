defmodule Mix.Tasks.Spendable.Transactions do
  use Mix.Task

  @shortdoc "Fetch transactions from the bank"

  @requirements ["app.start"]

  @moduledoc """
  Fetch transactions from the bank.

  ## Examples

      mix transactions
  """
  alias Spendable.Transactions

  @impl Mix.Task
  def run(_args) do
    IO.puts("Fetching transactions...")
    {:ok, _} = Application.ensure_all_started(:spendable)
    Transactions.import_transactions()
    IO.puts("Transactions fetched successfully.")
  end
end

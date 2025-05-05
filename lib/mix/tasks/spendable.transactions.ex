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
    Mix.shell().info("Fetching transactions...")
    Transactions.import_transactions()
    Mix.shell().info("Transactions fetched successfully.")
  end
end

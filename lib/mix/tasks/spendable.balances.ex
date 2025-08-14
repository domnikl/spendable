defmodule Mix.Tasks.Spendable.Balances do
  use Mix.Task

  @shortdoc "Import account balances from the bank"

  @requirements ["app.start"]

  @moduledoc """
  Import account balances from the bank.

  ## Examples

      mix spendable.balances
  """

  alias Spendable.Accounts
  alias Gocardless.GocardlessApi

  @impl Mix.Task
  def run(_args) do
    IO.puts("Importing account balances...")

    case import_balances() do
      {:ok, count} ->
        IO.puts("Successfully imported balances for #{count} accounts.")

      {:error, reason} ->
        IO.puts(:stderr, "Failed to import balances: #{inspect(reason)}")
    end
  end

  defp import_balances() do
    accounts = Accounts.active_gocardless_accounts()

    if Enum.empty?(accounts) do
      IO.puts(:stderr, "No active GoCardless accounts found.")
      {:ok, 0}
    else
      results =
        accounts
        |> Enum.map(&import_account_balance/1)
        |> Enum.filter(&match?({:ok, _}, &1))

      if length(results) == length(accounts) do
        {:ok, length(results)}
      else
        {:error, "Failed to import some account balances"}
      end
    end
  end

  defp import_account_balance(account) do
    IO.puts("Importing balance for account: #{account.account_id}")

    with {:ok, token} <- get_access_token(),
         {:ok, balance_response} <- GocardlessApi.get_balances(token, account.account_id),
         :ok <- process_balances(account, balance_response.balances) do
      {:ok, account}
    else
      {:error, reason} ->
        IO.puts(
          :stderr,
          "Failed to import balance for account #{account.account_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp get_access_token() do
    secret_id = System.get_env("GOCARDLESS_SECRET_ID")
    secret_key = System.get_env("GOCARDLESS_SECRET_KEY")

    if secret_id && secret_key do
      GocardlessApi.get_access_token(secret_id, secret_key)
      |> case do
        {:ok, response} -> {:ok, response.access}
        error -> error
      end
    else
      {:error,
       "Missing GoCardless credentials. Set GOCARDLESS_SECRET_ID and GOCARDLESS_SECRET_KEY environment variables."}
    end
  end

  defp process_balances(account, balances) when is_list(balances) do
    balances
    |> Enum.each(fn balance ->
      case parse_balance_amount(balance) do
        {:ok, amount_cents, currency} ->
          today = Date.utc_today()

          case Accounts.upsert_account_balance(account, today, amount_cents, currency) do
            {:ok, _balance} ->
              amount_display = amount_cents / 100

              IO.puts("  Updated balance: #{amount_display} #{currency} (#{amount_cents} cents)")

            {:error, changeset} ->
              IO.puts(:stderr, "  Failed to save balance: #{inspect(changeset.errors)}")
          end

        {:error, reason} ->
          IO.puts(:stderr, "  Failed to parse balance: #{reason}")
      end
    end)

    :ok
  end

  defp parse_balance_amount(%{
         "balanceAmount" => %{"amount" => amount_str, "currency" => currency}
       }) do
    case Accounts.convert_to_cents(amount_str) do
      amount_cents when is_integer(amount_cents) -> {:ok, amount_cents, currency}
      _ -> {:error, "Invalid amount format: #{amount_str}"}
    end
  rescue
    _ -> {:error, "Invalid amount format: #{amount_str}"}
  end

  defp parse_balance_amount(balance) do
    {:error, "Invalid balance format: #{inspect(balance)}"}
  end
end

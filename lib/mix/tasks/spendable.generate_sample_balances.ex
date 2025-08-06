defmodule Mix.Tasks.Spendable.GenerateSampleBalances do
  @moduledoc """
  Generates sample balance data for testing the balance chart.
  
  ## Examples
  
      $ mix spendable.generate_sample_balances
      
  This task creates sample balance data for all user accounts.
  """
  
  use Mix.Task
  alias Spendable.{Accounts, Users, Repo}
  alias Spendable.Accounts.{Account, AccountBalance}
  import Ecto.Query

  @shortdoc "Generate sample balance data for chart testing"

  def run(_) do
    Mix.Task.run("app.start")

    IO.puts("🏦 Generating Sample Balance Data for Chart Testing")
    IO.puts("")

    # Get all active accounts
    accounts = 
      Repo.all(
        from a in Account,
          where: a.active == true
      )

    if Enum.empty?(accounts) do
      IO.puts("❌ No accounts found. Please create some accounts first.")
    else
      IO.puts("Found #{length(accounts)} accounts to generate data for...")

      for account <- accounts do
        IO.puts("🏛️  Account: #{account.product} (#{account.owner_name})")
        
        # Generate 12 months of daily balance data
        generate_balance_data_for_account(account)
      end

      IO.puts("")
      IO.puts("✅ Sample balance data generation complete!")
      IO.puts("🎯 You can now view the balance chart on the dashboard.")
    end
  end

  defp generate_balance_data_for_account(account) do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -365)  # 12 months ago
    
    # Generate a realistic balance progression
    base_balance = :rand.uniform(5000) + 1000  # Between 1000-6000 EUR
    current_balance = base_balance * 100  # Convert to cents
    
    # Generate daily balances with realistic fluctuations
    dates = Date.range(start_date, end_date) |> Enum.to_list()
    
    {_, _final_balance} = 
      Enum.reduce(dates, {current_balance, []}, fn date, {balance, acc} ->
        # Random daily change between -200 and +150 EUR (in cents)
        daily_change = :rand.uniform(35000) - 20000  # -200 to +150 EUR
        new_balance = max(balance + daily_change, 0)  # Don't go negative
        
        # Only create balance entries for some days (not every day has data)
        if :rand.uniform(100) <= 70 do  # 70% chance of having data for this day
          # Use upsert to avoid duplicates
          case Accounts.upsert_account_balance(account, date, new_balance, account.currency) do
            {:ok, _} -> :ok
            {:error, _} -> :ok  # Ignore errors for this sample data
          end
        end
        
        {new_balance, [new_balance | acc]}
      end)
    
    IO.puts("    ✅ Generated #{length(dates)} days of balance data")
  end
end
# Spendable

A selfhosted spendings and budget tracker app written in Elixir.

## Development

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- Mix tasks to import data from Gocardless (see below):
  - `mix spendable.transactions` to import transactions (rate limited to 4/day)
  - `mix spendable.balances` to import balances for active accounts (rate limited to 4/day)

Now you can visit [`localhost:4001`](http://localhost:4001) from your browser.

## Gocardless

To sync bank account data and transactions, Spendable heavily relies on Gocardless' Bank Account Data API. You can find the developer documentation [here](https://developer.gocardless.com/bank-account-data/endpoints). An account and corresponding API

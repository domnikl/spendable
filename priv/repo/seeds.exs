# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Spendable.Repo.insert!(%Spendable.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Spendable.Repo

{:ok, user} =
  Spendable.Users.register_user(%{
    email: "john@doe.com",
    password: "password123456789",
    password_confirmation: "password123456789"
  })

account =
  Repo.insert!(%Spendable.Accounts.Account{
    account_id: "1234567890",
    type: :manual,
    product: "Checking Account",
    bic: "DEUTDEDBFRA",
    owner_name: "John Doe",
    iban: "DE12345678901234567890",
    currency: "EUR",
    balance: 10000,
    active: true,
    user_id: user.id
  })

Repo.insert!(%Spendable.Transactions.Transaction{
  transaction_id: "1234567890",
  counter_name: "Jane Doe",
  counter_iban: "DE12345678901234567890",
  amount: 10033,
  currency: "EUR",
  booking_date: ~D[2023-10-01],
  value_date: ~D[2023-10-01],
  purpose_code: "SALA",
  description: "Salary for October 2023",
  user_id: user.id,
  account_id: account.id
})

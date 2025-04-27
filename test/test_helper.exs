ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Spendable.Repo, :manual)

# Τhis configures Mox to use the MockGithubApi module as the API implementation in tests.
# Using a short and descriptive name for the mock module works best and makes life easier.
Mox.defmock(MockGocardlessApi, for: Gocardless.GocardlessApi)

Application.put_env(:spendable, Gocardless.GocardlessApi, MockGocardlessApi)

defmodule Gocardless.GocardlessApi.GetAccountDetailsResponse do
  @type t :: %__MODULE__{
          iban: String.t(),
          currency: String.t(),
          owner_name: String.t(),
          product: String.t(),
          bic: String.t()
        }

  defstruct iban: nil,
            currency: nil,
            owner_name: nil,
            product: nil,
            bic: nil

  def new(json_response) do
    account = Map.get(json_response, "account")

    %__MODULE__{
      iban: Map.get(account, "iban"),
      currency: Map.get(account, "currency"),
      owner_name: Map.get(account, "ownerName"),
      product: Map.get(account, "product"),
      bic: Map.get(account, "bic")
    }
  end
end

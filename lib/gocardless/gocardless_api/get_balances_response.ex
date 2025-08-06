defmodule Gocardless.GocardlessApi.GetBalancesResponse do
  defstruct [:balances]

  @type t :: %__MODULE__{
          balances: [map()]
        }

  def new(data) do
    %__MODULE__{
      balances: data["balances"] || []
    }
  end
end
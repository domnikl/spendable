defmodule Gocardless.GocardlessApi.PostAgreementRequest do
  @type t :: %__MODULE__{
          institution_id: String.t(),
          max_historical_days: integer(),
          access_valid_for_days: integer(),
          access_scope: [String.t()]
        }

  @derive Jason.Encoder
  defstruct institution_id: nil,
            max_historical_days: nil,
            access_valid_for_days: nil,
            access_scope: []
end

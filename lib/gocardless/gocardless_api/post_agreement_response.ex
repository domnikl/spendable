defmodule Gocardless.GocardlessApi.PostAgreementResponse do
  @type t :: %__MODULE__{
          id: String.t(),
          created: DateTime.t(),
          institution_id: String.t(),
          max_historical_days: integer(),
          access_valid_for_days: integer(),
          access_scope: [String.t()]
        }

  defstruct id: nil,
            created: nil,
            institution_id: nil,
            max_historical_days: nil,
            access_valid_for_days: nil,
            access_scope: []

  def new(json_response) do
    %__MODULE__{
      id: Map.get(json_response, "id"),
      created: Map.get(json_response, "created"),
      institution_id: Map.get(json_response, "institution_id"),
      max_historical_days: Map.get(json_response, "max_historical_days"),
      access_valid_for_days: Map.get(json_response, "access_valid_for_days"),
      access_scope: Map.get(json_response, "access_scope")
    }
  end
end

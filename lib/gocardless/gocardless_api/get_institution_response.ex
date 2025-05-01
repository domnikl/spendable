defmodule Gocardless.GocardlessApi.GetInstitutionResponse do
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          bic: String.t(),
          transaction_total_days: String.t(),
          countries: [String.t()],
          logo: String.t(),
          max_access_valid_for_days: String.t()
        }

  defstruct id: nil,
            name: nil,
            bic: nil,
            transaction_total_days: nil,
            countries: [],
            logo: nil,
            max_access_valid_for_days: nil

  def new(json_response) do
    %__MODULE__{
      id: Map.get(json_response, "id"),
      name: Map.get(json_response, "name"),
      bic: Map.get(json_response, "bic"),
      transaction_total_days: Map.get(json_response, "transaction_total_days"),
      countries: Map.get(json_response, "countries"),
      logo: Map.get(json_response, "logo"),
      max_access_valid_for_days: Map.get(json_response, "max_access_valid_for_days")
    }
  end
end

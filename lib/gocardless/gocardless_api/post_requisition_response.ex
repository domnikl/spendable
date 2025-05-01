defmodule Gocardless.GocardlessApi.PostRequisitionResponse do
  @type t :: %__MODULE__{
          id: String.t(),
          created: DateTime.t(),
          redirect: String.t(),
          status: String.t(),
          institution_id: String.t(),
          agreement: String.t(),
          reference: String.t(),
          accounts: [String.t()],
          user_language: String.t(),
          link: String.t(),
          ssn: String.t(),
          account_selection: false | true,
          redirect_immediate: false | true
        }

  defstruct id: nil,
            created: nil,
            redirect: nil,
            status: nil,
            institution_id: nil,
            agreement: nil,
            reference: nil,
            accounts: [],
            user_language: nil,
            link: nil,
            ssn: nil,
            account_selection: false,
            redirect_immediate: false

  def new(json_response) do
    %__MODULE__{
      id: Map.get(json_response, "id"),
      created: Map.get(json_response, "created"),
      redirect: Map.get(json_response, "redirect"),
      status: Map.get(json_response, "status"),
      institution_id: Map.get(json_response, "institution_id"),
      agreement: Map.get(json_response, "agreement"),
      reference: Map.get(json_response, "reference"),
      accounts: Map.get(json_response, "accounts"),
      user_language: Map.get(json_response, "user_language"),
      link: Map.get(json_response, "link"),
      ssn: Map.get(json_response, "ssn"),
      account_selection: Map.get(json_response, "account_selection", false),
      redirect_immediate: Map.get(json_response, "redirect_immediate", false)
    }
  end
end

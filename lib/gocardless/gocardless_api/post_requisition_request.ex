defmodule Gocardless.GocardlessApi.PostRequisitionRequest do
  @type t :: %__MODULE__{
          institution_id: String.t(),
          agreement_id: String.t(),
          reference: String.t(),
          redirect: String.t(),
          user_language: String.t()
        }

  defstruct institution_id: nil,
            agreement_id: nil,
            reference: nil,
            redirect: nil,
            user_language: nil
end

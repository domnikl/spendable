defmodule Gocardless.GocardlessApi.PostRequisitionRequest do
  @type t :: %__MODULE__{
          institution_id: String.t(),
          agreement: String.t(),
          reference: String.t(),
          redirect: String.t(),
          user_language: String.t()
        }

  @derive Jason.Encoder
  defstruct institution_id: nil,
            agreement: nil,
            reference: nil,
            redirect: nil,
            user_language: nil
end

defmodule Gocardless.GocardlessApi.RefreshTokenResponse do
  @type t :: %__MODULE__{
          access: String.t(),
          access_expires: String.t()
        }

  defstruct access: nil,
            access_expires: nil

  def new(json_response) do
    %__MODULE__{
      access: Map.get(json_response, "access"),
      access_expires: Map.get(json_response, "access_expires")
    }
  end
end

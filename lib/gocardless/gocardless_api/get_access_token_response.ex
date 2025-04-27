defmodule Gocardless.GocardlessApi.GetAccessTokenResponse do
  @type t :: %__MODULE__{
          access: String.t(),
          access_expires: String.t(),
          refresh: String.t(),
          refresh_expires: String.t()
        }

  defstruct access: nil,
            access_expires: nil,
            refresh: nil,
            refresh_expires: nil

  def new(json_response) do
    %__MODULE__{
      access: Map.get(json_response, "access"),
      access_expires: Map.get(json_response, "access_expires"),
      refresh: Map.get(json_response, "refresh"),
      refresh_expires: Map.get(json_response, "refresh_expires")
    }
  end
end

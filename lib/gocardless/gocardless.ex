defmodule Gocardless.Gocardless do
  use Supervisor

  def start_link(config) do
    children = [
      {Finch, name: Gocardless.Finch},
      {Gocardless.Client, config}
    ]

    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end

  def init(children) do
    Supervisor.init(children, strategy: :one_for_one)
  end
end

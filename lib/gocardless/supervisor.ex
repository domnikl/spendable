defmodule Gocardless.Supervisor do
  use Supervisor

  def start_link(_) do
    children = [
      {Finch, name: GocardlessApi},
      {Gocardless.Client, []}
    ]

    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end

  def init(children) do
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Scanner.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [Scanner.Coordinator]
    opts = [strategy: :one_for_one, name: Scanner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

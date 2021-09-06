defmodule RSS.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: RSS.Finch},
      RSS.Feeds.Cache,
      {Aino, callback: RSS.Handler, port: 3000}
    ]

    opts = [strategy: :one_for_one, name: RSS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
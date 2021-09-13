defmodule RSS.Handler do
  @moduledoc false

  import Aino.Middleware.Routes, only: [get: 2, post: 2]

  alias RSS.Feeds
  alias RSS.Pages
  alias RSS.Layout

  @behaviour Aino.Handler

  @impl true
  def handle(token) do
    routes = [
      get("/", &Pages.index/1),
      get("/items/:id", &Pages.item/1),
      post("/feeds", &Feeds.create/1)
    ]

    wrappers = [
      &Aino.Middleware.Development.recompile/1,
      Aino.Middleware.common(),
      &Aino.Middleware.Routes.routes(&1, routes),
      &Aino.Middleware.Routes.match_route/1,
      &Aino.Middleware.params/1,
      &Aino.Middleware.Routes.handle_route/1,
      &Layout.wrap/1,
    ]

    Aino.Token.reduce(token, wrappers)
  end
end

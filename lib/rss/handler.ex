defmodule RSS.Handler do
  @moduledoc false

  import Aino.Routes, only: [get: 2, post: 2]

  alias RSS.Feeds
  alias RSS.Pages
  alias RSS.Layout

  def handle(token) do
    routes = [
      get("/", &Pages.index/1),
      get("/items/:id", &Pages.item/1),
      post("/feeds", &Feeds.create/1)
    ]

    wrappers = [
      Aino.Wrappers.common(),
      &Aino.Routes.routes(&1, routes),
      &Aino.Routes.match_route/1,
      &Aino.Wrappers.params/1,
      &Aino.Routes.handle_route/1,
      &Layout.wrap/1,
    ]

    Aino.Token.reduce(token, wrappers)
  end
end

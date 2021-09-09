defmodule RSS.Pages do
  alias Aino.Token
  alias Aino.Token.Response
  alias RSS.Feeds
  alias RSS.Pages.View

  def index(token) do
    feeds = Feeds.Cache.all()

    token
    |> Token.response_status(200)
    |> Response.html(View.render("index.html", %{feeds: feeds}))
  end

  def item(%{params: %{"id" => item_id}} = token) do
    case Feeds.Cache.get(item_id) do
      {:ok, item} ->
        token
        |> Token.response_status(200)
        |> Response.html(View.render("item.html", %{item: item}))

      {:error, :not_found} ->
        token
        |> Token.response_status(404)
        |> Response.html(View.render("not-found.html"))
    end
  end
end

defmodule RSS.Pages.View do
  require Aino.View

  Aino.View.compile [
    "lib/rss/templates/pages/index.html.eex",
    "lib/rss/templates/pages/item.html.eex",
    "lib/rss/templates/pages/not-found.html.eex"
  ]
end

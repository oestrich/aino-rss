defmodule RSS.Pages do
  alias Aino.Token
  alias RSS.Feeds.Cache, as: Feeds
  alias RSS.Pages.View

  def index(token) do
    feeds = Feeds.get()

    token
    |> Token.response_status(200)
    |> Token.response_header("Content-Type", "text/html")
    |> Token.response_body(View.render("index.html", %{feeds: feeds}))
  end

  def item(%{path_params: %{id: item_id}} = token) do
    item = Feeds.get(item_id)

    token
    |> Token.response_status(200)
    |> Token.response_header("Content-Type", "text/html")
    |> Token.response_body(View.render("item.html", %{item: item}))
  end
end

defmodule RSS.Pages.View do
  require EEx

  EEx.function_from_file(:def, :render_index, "lib/rss/templates/pages/index.html.eex", [:assigns])
  EEx.function_from_file(:def, :render_item, "lib/rss/templates/pages/item.html.eex", [:assigns])

  def render("index.html", assigns), do: render_index(assigns)

  def render("item.html", assigns), do: render_item(assigns)
end

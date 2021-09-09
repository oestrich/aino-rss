defmodule RSS.Layout do
  alias Aino.Token

  require Aino.View

  def wrap(token) do
    Token.response_body(token, render("app.html", %{inner_content: token.response_body}))
  end

  Aino.View.compile [
    "lib/rss/templates/layout/app.html.eex"
  ]
end

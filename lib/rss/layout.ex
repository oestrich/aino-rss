defmodule RSS.Layout do
  alias Aino.Token

  require EEx
  EEx.function_from_file(:def, :render, "lib/rss/templates/layout/app.html.eex", [:assigns])

  def wrap(token) do
    Token.response_body(token,  render(%{inner_content: token.response_body}))
  end
end

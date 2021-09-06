defmodule RSS.Feeds do
  alias Aino.Token
  alias RSS.Feeds.Cache, as: Feeds

  def create(token) do
    case Feeds.cache(token.parsed_body["feed_url"]) do
      :ok ->
        token
        |> Token.response_status(302)
        |> Token.response_header("Content-Type", "text/html")
        |> Token.response_header("Location", "/")
        |> Token.response_body("Redirecting...")
    end
  end
end

defmodule RSS.Feeds.Remote do
  import SweetXml, only: [sigil_x: 2]

  def fetch(url) do
    request = Finch.build(:get, url)

    case Finch.request(request, RSS.Finch) do
      {:ok, %{status: 200, body: body}} ->
        feed =
          SweetXml.xmap(body, [
            title: ~x"/rss/channel/title/text()"s,
            items: [
              ~x"//item"l,
              title: ~x"./title/text()"s,
              link: ~x"./link/text()"s,
              text: ~x"./content:encoded/text()"s,
              guid: ~x"./guid/text()"s |> SweetXml.transform_by(&guid/1)
            ]
          ])

        {:ok, feed}
    end
  end

  def guid(text) do
    Base.url_encode64(:crypto.hash(:sha256, text))
  end
end

defmodule RSS.Feeds.Cache do
  use GenServer

  alias RSS.Feeds.Remote

  def all() do
    []
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get() do
    Map.values(:sys.get_state(__MODULE__))
  end

  def get(item_id) do
    get()
    |> Enum.flat_map(fn feed ->
      Enum.map(feed.items, fn item ->
        Map.put(item, :feed, feed.title)
      end)
    end)
    |> Enum.find(fn item ->
      item.guid == item_id
    end)
  end

  def cache(url) do
    GenServer.call(__MODULE__, {:cache, url})
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :refresh, 60 * 60 * 1000)

    {:ok, %{}, {:continue, :cache}}
  end

  @impl true
  def handle_continue(:cache, state) do
    state =
      Enum.reduce(all(), state, fn url, state ->
        {:ok, feed} = Remote.fetch(url)
        Map.put(state, url, feed)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:cache, url}, _from, state) do
    {:ok, feed} = Remote.fetch(url)
    state = Map.put(state, url, feed)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    state =
      Enum.reduce(Map.keys(state), state, fn url, state ->
        {:ok, feed} = Remote.fetch(url)
        Map.put(state, url, feed)
      end)

    {:noreply, state}
  end
end

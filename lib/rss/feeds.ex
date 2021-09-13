defmodule RSS.Feeds do
  alias Aino.Token.Response
  alias RSS.Feeds

  def create(token) do
    case Feeds.Fetcher.cache_feed(token.parsed_body["feed_url"]) do
      :ok ->
        Response.redirect(token, "/")
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
              text: ~x"./content:encoded/text()"s |> SweetXml.transform_by(&sanitize/1),
              guid: ~x"./guid/text()"s |> SweetXml.transform_by(&guid/1)
            ]
          ])

        feed = Map.put(feed, :url, url)

        {:ok, feed}
    end
  end

  def sanitize(text) do
    HtmlSanitizeEx.basic_html(text)
  end

  def guid(text) do
    Base.url_encode64(:crypto.hash(:sha256, text))
  end
end

defmodule RSS.Feeds.Fetcher do
  use GenServer

  alias RSS.Feeds.Cache
  alias RSS.Feeds.Remote

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def cache_feed(url) do
    GenServer.cast(__MODULE__, {:cache, url})
  end

  @impl true
  def init(_) do
    {:ok, :undefined}
  end

  @impl true
  def handle_cast({:cache, url}, state) do
    {:ok, feed} = Remote.fetch(url)

    Cache.cache_feed(feed)

    Enum.each(feed.items, fn item ->
      item = Map.put(item, :feed, feed.title)
      Cache.cache_item(item)
    end)

    {:noreply, state}
  end
end

defmodule RSS.Feeds.Refresher do
  use GenServer

  require Logger

  alias RSS.Feeds.Cache
  alias RSS.Feeds.Fetcher

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def refresh() do
    GenServer.cast(__MODULE__, :refresh)
  end

  @impl true
  def init(_) do
    state = refresh_async(%{})

    {:ok, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    Logger.info("Refreshing feeds")

    Enum.map(Cache.all(), fn feed ->
      Fetcher.cache_feed(feed.url)
    end)

    state = refresh_async(state)

    {:noreply, state}
  end

  defp refresh_async(state) do
    ref = Process.send_after(self(), :refresh, 10 * 60 * 1000)
    Map.put(state, :refresh_ref, ref)
  end
end

defmodule RSS.Feeds.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def all() do
    Enum.map(keys(:rss_feeds), fn key ->
      case :ets.lookup(:rss_feeds, key) do
        [{^key, feed}] ->
          feed

        [] ->
          nil
      end
    end)
  end

  @doc false
  def keys(ets_key) do
    key = :ets.first(ets_key)
    keys(key, [], ets_key)
  end

  @doc false
  def keys(:"$end_of_table", accumulator, _ets_key), do: accumulator

  def keys(current_key, accumulator, ets_key) do
    next_key = :ets.next(ets_key, current_key)
    keys(next_key, [current_key | accumulator], ets_key)
  end

  def get(item_id) do
    case :ets.lookup(:rss_items, item_id) do
      [{_key, item}] ->
        {:ok, item}

      [] ->
        {:error, :not_found}
    end
  end

  @doc false
  def cache_feed(feed) do
    GenServer.call(__MODULE__, {:cache_feed, feed})
  end

  @doc false
  def cache_item(item) do
    GenServer.call(__MODULE__, {:cache_item, item})
  end

  @impl true
  def init(_) do
    :ets.new(:rss_feeds, [:set, :protected, :named_table])
    :ets.new(:rss_items, [:set, :protected, :named_table])

    {:ok, :undefined}
  end

  @impl true
  def handle_call({:cache_feed, feed}, _from, state) do
    :ets.insert(:rss_feeds, {feed.url, feed})

    {:reply, :ok, state}
  end

  def handle_call({:cache_item, item}, _from, state) do
    :ets.insert(:rss_items, {item.guid, item})

    {:reply, :ok, state}
  end
end

defmodule Kerosene do
  defstruct items: [], per_page: 0, max_page: 0, page: 0, total_pages: 0, total_count: 0, params: []
  import Ecto.Query

  @per_page 10
  @max_page 100
  @page 1

  @moduledoc """
  Pagination for Ecto and Phoenix.
  """

  defmacro __using__(opts \\ []) do
    quote do
      def paginate(query, params \\ %{}, options \\ []) do
        Kerosene.paginate( __MODULE__, query, params,
          Keyword.merge(unquote(opts), options))
      end
    end
  end

  def paginate(repo, query, params, opts) do
    paginate(repo, query, build_options(opts, params))
  end

  def paginate(repo, query, opts) do
    per_page = Keyword.get(opts, :per_page)
    max_page = Keyword.get(opts, :max_page)
    total_count = get_total_count(opts[:total_count], repo, query)
    total_pages = get_total_pages(total_count, per_page)
    page = get_page(opts, total_pages)
    offset = get_offset(total_count, page)

    kerosene = %Kerosene {
      per_page: per_page,
      page: page,
      total_pages: total_pages,
      total_count: total_count,
      max_page: max_page,
      params: opts[:params]
    }

    {get_items(repo, query, per_page, offset), kerosene}
  end

  defp get_items(repo, query, nil, _), do: repo.all(query)
  defp get_items(repo, query, limit, offset) do
    query
    |> limit(^limit)
    |> offset(^offset)
    |> repo.all
  end

  defp get_offset(total_pages, page) do
    page = case page > total_pages do
      true -> total_pages
      _ -> page
    end

    case page > 0 do
      true -> page - 1
      _ -> page
    end
  end

  defp get_total_count(count, _repo, _query) when is_integer(count) and count >= 0, do: count
  defp get_total_count(_count, repo, query) do
    primary_key = get_primary_key(query)

    total_pages =
      query
      |> exclude(:preload)
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([i], count(field(i, ^primary_key), :distinct))
      |> repo.one

    total_pages || 0
  end

  def get_primary_key(query) do
    new_query = case is_map(query) do
      true -> query.from |> elem(1)
      _ -> query
    end

    new_query
    |> apply(:__schema__, [:primary_key])
    |> hd
  end

  def get_total_pages(_, nil), do: 1
  def get_total_pages(count, per_page) do
    Float.ceil(count / per_page) |> trunc()
  end

  def get_page(params, total_pages) do
    case params[:page] > params[:max_page] do
      true -> total_pages
      _ -> params[:page]
    end
  end

  defp build_options(opts, params) do
    page = Map.get(params, "page", @page) |> to_integer()
    per_page = default_per_page(opts) |> to_integer()
    max_page = Keyword.get(opts, :max_page, default_max_page())
    Keyword.merge(opts, [page: page, per_page: per_page, params: params, max_page: max_page])
  end

  defp default_per_page(opts) do
    case Keyword.get(opts, :per_page) do
      nil -> Application.get_env(:kerosene, :per_page, @per_page)
      per_page -> per_page
    end
  end

  defp default_max_page() do
    Application.get_env(:kerosene, :max_page, @max_page)
  end

  def to_integer(i) when is_integer(i), do: abs(i)
  def to_integer(i) when is_binary(i) do
    case Integer.parse(i) do
      {n, _} -> n
      _ -> 0
    end
  end
  def to_integer(_), do: @page
end

defmodule Kerosene do
  defstruct items: [], per_page: 10, page: 1, total_pages: 0, total_count: 0, params: []
  import Ecto.Query

  @moduledoc """
  Pagination for Ecto and Phoenix.
  """

  defmacro __using__(opts \\ []) do
    quote do
      def paginate(query, params \\ %{}, options \\ []) do
        opts = Keyword.merge(unquote(opts), options)
        Kerosene.paginate(__MODULE__, query, params, opts)
      end
    end
  end

  def paginate(repo, query, params, opts) do
    paginate(repo, query, merge_options(opts, params))
  end

  def paginate(repo, query, opts) do
    per_page = get_per_page(opts)
    page = get_page(opts)
    total_count = get_total_count(repo, query)

    kerosene = %Kerosene {
      per_page: per_page,
      page: page,
      total_pages: get_total_pages(total_count, per_page),
      total_count: total_count,
      params: opts[:params]
    }

    {get_items(repo, query, per_page, page), kerosene}
  end

  defp get_items(repo, query, per_page, page) do
    offset = per_page * (page - 1)
    query
    |> limit(^per_page)
    |> offset(^offset)
    |> repo.all
  end

  defp get_total_count(repo, query) do
    primary_key = get_primary_key(query)

    query
    |> exclude(:preload)
    |> exclude(:order_by)
    |> exclude(:select)
    |> select([i], count(field(i, ^primary_key), :distinct))
    |> repo.one
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

  def get_total_pages(count, per_page) do
    Float.ceil(count / per_page) |> trunc
  end

  def get_per_page(params) do
    params 
    |> Keyword.get(:per_page, 10) 
    |> to_integer
  end

  def get_page(params) do
    params 
    |> Keyword.get(:page, 1) 
    |> to_integer
  end

  defp merge_options(opts, params) do
    page = Map.get(params, "page", 1)
    per_page = Map.get(params, "per_page", opts[:per_page])
    Keyword.merge(opts, [page: page, per_page: per_page, params: params])
  end

  def to_integer(i) when is_integer(i), do: i
  def to_integer(i) when is_binary(i), do: String.to_integer(i)
  def to_integer(_), do: 1
end

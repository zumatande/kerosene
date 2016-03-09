defmodule Kerosene do
  defstruct items: [], per_page: 10, page: 1, total_pages: 0, total_count: 0
  import Ecto.Query

  defmacro __using__(opts \\ []) do
    quote do
      def paginate(query, params) do
        Kerosene.paginate(__MODULE__, query, unquote(opts), params)
      end
    end
  end

  def paginate(repo, query, opts, params) do
    paginate(repo, query, merge_options(opts, params))
  end

  def paginate(repo, query, params) do
    per_page = params |> Keyword.get(:per_page, 10) |> to_integer
    page = params |> Keyword.get(:page, 1) |> to_integer
    total_count = get_total_count(repo, query)

    %Kerosene{
      items: get_items(repo, query, per_page, page),
      per_page: per_page,
      page: page,
      total_pages: get_total_pages(total_count, per_page),
      total_count: total_count
    }
  end

  defp get_items(repo, query, per_page, page) do
    offset = per_page * (page - 1)
    query
      |> limit(^per_page)
      |> offset(^offset)
      |> repo.all
  end

  defp get_total_pages(count, per_page) do
    Float.ceil(count / per_page) |> trunc
  end

  defp get_total_count(repo, query) do
    count = query
      |> select([i], count(i.id))
      |> repo.one
  end

  def merge_options(opts, params) do
    opts_from_params = for {key, val} <- params, into: [], do: {String.to_atom(key), val}
    Keyword.merge(opts, opts_from_params)
  end

  defp to_integer(i) when is_integer(i), do: i
  defp to_integer(i) when is_binary(i), do: String.to_integer(i)
  defp to_integer(_), do: 0
end
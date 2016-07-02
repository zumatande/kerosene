defmodule Kerosene.HTML do
  use Phoenix.HTML
  alias Kerosene.HTML

  @default [theme: :bootstrap, window: 3, next_label: "Next", previous_label: "Previous", first: true, first_label: "First", last: true, last_label: "Last"]
  @themes [:bootstrap, :bootstrap4, :foundation, :semantic]

  @moduledoc """
  Html helpers to render the pagination links and more,
  import the `Kerosene.HTML` in your view module.

      defmodule MyApp.PostView do
        use MyApp.Web, :view
        import Kerosene.HTML
      end

  now you have these view helpers in your template file.
      <%= paginate @conn, @page %>

  Where `@page` is a `%Kerosene{}` struct returned from `Repo.paginate/2`.

  `paginate` helper takes keyword list of `options` and `params`.
    <%= paginate @conn, @page, window: 5, next_label: ">>", previous_label: "<<", first: true, last: true, first_label: "First", last_label: "Last" %>
  """

  @doc """
  Generates the HTML pagination links for a given page returned by Kerosene.

  The default options are:

      #{inspect @default}

  The `theme` indicates which CSS framework you are using. The default is
  `:bootstrap`, but you can add your own using the `Kerosene.HTML.raw_paginate/2` function
  if desired. Kerosene provides few themes out of the box:

      #{inspect @themes}

  Example:

      iex> Kerosene.HTML.paginate(%Kerosene{page: 5, per_page: 10})

  You can override the path by adding an extra key in the `opts` parameter of `:path`.
  For example:

      Kerosene.HTML.paginate(@conn, @page, path: post_comment_path(@conn, :index, foo: "bar"))
  """
  defmacro __using__(_opts \\ []) do
    quote do
      import Kerosene.HTML
    end
  end

  def paginate(conn, paginator, opts \\ [], params \\ []) do
    path = opts[:path] || build_url(conn, params)
    opts = build_options(Keyword.merge(opts, [path: path]), params)

    conn 
    |> build_page_list(paginator, opts) 
    |> render_page_list(opts)
  end

  @doc false
  def build_page_list(conn, paginator, opts \\ []) do
    page = paginator.page
    total_pages = paginator.total_pages
    params = paginator.params

    page
    |> previous_page
    |> first_page(page, opts[:window], opts[:first])
    |> page_list(page, total_pages, opts[:window])
    |> next_page(page, total_pages)
    |> last_page(page, total_pages, opts[:window], opts[:last])
    |> Enum.map(fn {l, p} -> 
     {label_text(l, opts), p, build_url(conn, Keyword.merge(params, [page: p])), page == p} 
    end)
  end

  def label_text(label, opts) do
    case label do
      :first    -> opts[:first_label]
      :previous -> opts[:previous_label]
      :next     -> opts[:next_label]
      :last     -> opts[:last_label]
      _         -> label
    end
  end

  def render_page_list(page_list, opts) do
    case opts[:theme] do
      :bootstrap  -> HTML.Boostrap.generate_links(page_list)
      :bootstrap4 -> HTML.Boostrap4.generate_links(page_list)
      :foundation -> HTML.Foundation.generate_links(page_list)
      :semantic   -> HTML.Semantic.generate_links(page_list)
      _           -> HTML.Simple.generate_links(page_list)
    end
  end

  # Computing page number ranges
  def page_list(list, page, total, window) when is_integer(window) and window >= 1 do
    page_list = left(page, window)..right(page, window, total) 
    |> Enum.map(fn n -> {n, n} end)
    list ++ page_list
  end
  def page_list(_list, _page, _total, _window) do
    raise "Kerosene.HTML: window cannot be less than one."
  end

  def left(page, window) when page - window < 1 do
    page - (window + (page - window - 1))
  end
  def left(page, window), do: page - window

  def right(page, _window, 0), do: page
  def right(page, window, total) when page + window >= total do
    total
  end
  def right(page, window, _total), do: page + window

  def previous_page(page) when page > 1 do
    [{:previous, page - 1}]
  end
  def previous_page(_page), do: []

  def next_page(list, page, total) when page < total do
    list ++ [{:next, page + 1}]
  end
  def next_page(list, _page, _total), do: list

  def first_page(list, page, window, true) when page - window > 1 do
    [{:first, 1} | list]
  end
  def first_page(list, _page, _window, _included), do: list

  def last_page(list, page, total, window, true) when page + window < total do
    list ++ [{:last, total}]
  end
  def last_page(list, _page, _total, _window, _included), do: list

  def build_url(conn, []), do: conn.request_path
  def build_url(conn, params) do
    "#{conn.request_path}?#{build_query(params)}"
  end

  def build_query(params) do
    params |> URI.encode_query
  end

  defp build_options(opts, params) do
    theme = opts[:theme] || Application.get_env(:kerosene, :theme, :bootstrap)
    opts = Keyword.merge(opts, [params: params, theme: theme])
    Keyword.merge(@default, opts)
  end
end

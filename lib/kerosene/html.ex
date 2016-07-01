defmodule Kerosene.HTML do
  use Phoenix.HTML

  @default [theme: :bootstrap, window: 5, next_label: "Next", previous_label: "Previous", first: true, first_label: "First", last: true, last_label: "Last"]
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
    merged_opts = build_options(opts)
    path = merged_opts[:path] || build_url(conn, params)
    do_paginate(conn, paginator, theme: merged_opts[:theme], path: path, params: params, opts: merged_opts)
  end

  defp do_paginate(conn, paginator, opts) do
    conn |> build_page_list(paginator, opts) |> render_page_list(paginator, opts)
  end

  @doc false
  def build_page_list(conn, paginator, opts \\ []) do
    opts = Keyword.merge(@default, opts)

    paginator.page
      |> previous_page
      |> first_page(paginator.page, opts[:window], opts[:opts][:first])
      |> page_list(paginator.page, paginator.total_pages, opts[:window])
      |> next_page(paginator.page, paginator.total_pages)
      |> last_page(paginator.page, paginator.total_pages, opts[:window], opts[:opts][:last])
      |> Enum.map(fn {label, page} -> {label_text(label, opts), page, build_url(conn, Keyword.merge(paginator.params, [page: page]))} end)
  end

  defp label_text(label, opts) do
    opts = opts[:opts]
    case label do
      :first    -> opts[:first_label]
      :previous -> opts[:previous_label]
      :next     -> opts[:next_label]
      :last     -> opts[:last_label]
      _         -> label
    end
  end

  defp render_page_list(page_list, paginator, [theme: theme, path: _path, params: _params, opts: _opts]) do
    case theme do
      :bootstrap  -> Kerosene.HTML.Boostrap.generate_links(page_list, paginator)
      :bootstrap4 -> Kerosene.HTML.Boostrap4.generate_links(page_list, paginator)
      :foundation -> Kerosene.HTML.Foundation.generate_links(page_list, paginator)
      :semantic   -> Kerosene.HTML.Semantic.generate_links(page_list, paginator)
      _           -> generate_links(page_list, paginator)
    end
  end

  defp generate_links(page_list, _paginator) do
    content_tag :nav, class: "pagination" do
      for {label, _page, path} <- page_list do
        link "#{label}", to: path
      end
    end
  end

  # Computing page number ranges
  defp page_list(list, page, total, window) when is_integer(window) and window >= 1 do
    page_list = left(page, window)..right(page, window, total) |> Enum.map(fn n -> {n, n} end)
    list ++ page_list
  end
  defp page_list(_list, _page, _total, _window) do
    raise "Kerosene.HTML: window cannot be less than one."
  end

  defp left(page, window) when page - window < 1 do
    page - (window + (page - window - 1))
  end
  defp left(page, window), do: page - window

  defp right(page, _window, 0), do: page
  defp right(page, window, total) when page + window >= total do
    total
  end
  defp right(page, window, _total), do: page + window

  defp previous_page(page) when page > 1 do
    [{:previous, page - 1}]
  end
  defp previous_page(_page), do: []

  defp next_page(list, page, total) when page < total do
    list ++ [{:next, page + 1}]
  end
  defp next_page(list, _page, _total), do: list

  defp first_page(list, page, window, true) when page - window > 1 do
    [{:first, 1} | list]
  end
  defp first_page(list, _page, _window, _included), do: list

  defp last_page(list, page, total, window, true) when page + window < total do
    list ++ [{:last, total}]
  end
  defp last_page(list, _page, _total, _window, _included), do: list

  defp build_url(conn, []), do: conn.request_path
  defp build_url(conn, params) do
    "#{conn.request_path}?#{build_query(params)}"
  end

  defp build_query(params) do
    params
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join("&")
  end

  defp build_options(opts) do
    theme = opts[:theme] || Application.get_env(:kerosene, :theme, :bootstrap)
    opts = Keyword.merge(opts, [theme: theme])
    Keyword.merge(@default, opts)
  end
end

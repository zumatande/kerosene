defmodule Kerosene.HTML do
  use Phoenix.HTML

  @defaults [theme: :bootstrap]
  @themes [:bootstrap, :foundation, :semantic]
  @page_defaults [window: 5, next: "Next", previous: "Previous", first: true, last: true]

  @moduledoc """
  Html helpers to render the pagination links and more, 
  import the `Kerosene.HTMl` in your view module.

      defmodule MyApp.UserView do
        use MyApp.Web, :view
        import Kerosene.HTML
      end

  available helpers in your template file.
      <%= paginate @conn, @page %>

  Where `@page` is a `%Kerosene{}` struct returned from `Repo.paginate/2`.

  Paginate helper can aslo be customezed for each template file.
    <%= paginate @conn, @page, window: 5, next: ">>", previous: "<<", first: true, last: true %>
  """

  @doc """
  Generates the HTML pagination links for a given page returned by Kerosene.

  The default options are:

      #{inspect @defaults}

  The `theme` indicates which CSS framework you are using. The default is
  `:bootstrap`, but you can add your own using the `Kerosene.HTML.raw_paginate/2` function
  if desired. Kerosene provides few themes out of the box:

      #{inspect @themes}

  An example of the output data:

      iex> Kerosene.HTML.paginate(%Kerosene{page: 5, per_page: 10})

  In order to generate links with nested objects (such as a list of comments for a given post)
  it is necessary to pass those arguments. All arguments in the `args` parameter will be directly
  passed to the path helper function. Everything within `opts` which are not options will passed
  as `params` to the path helper function. For example, `@post`, which has an index of paginated
  `@comments` would look like the following:

      Kerosene.HTML.paginate(@conn, @comments, [@post], theme: :bootstrap, my_param: "foo")

  You'll need to be sure to configure `:kerosene` with the `:route_helpers`
  module (ex. MyApp.Routes.Helpers) in Phoenix. With that configured, the above would generate calls
  to the `post_comment_path(@conn, :index, @post.id, my_param: "foo", page: page)` for each page link.

  In times that it is necessary to override the automatic path function resolution, you may supply the
  correct path function to use by adding an extra key in the `opts` parameter of `:path`.
  For example:

      Kerosene.HTML.paginate(@conn, @comments, [@post], path: &post_comment_path/4)

  Be sure to supply the function which accepts query string parameters (starts at arity 3, +1 for each relation),
  because the `page` parameter will always be supplied. If you supply the wrong function you will receive a
  function undefined exception.
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

  defp do_paginate(_paginator, [theme: theme]) when not theme in @themes do
    raise "Kerosene.HTML: Theme #{inspect theme} is not a valid them. Please use one of #{inspect @themes}"
  end
  defp do_paginate(conn, paginator, opts) do
    conn |> build_page_list(paginator, opts) |> render_page_list(paginator, opts)
  end

  @doc """
  Returns the raw data in order to generate the proper HTML for pagination links. Data
  is returned in a `{text, page}` format where `text` is intended to be the text
  of the link and `page` is the page it should go to. Defaults are already supplied
  and they are as follows:

      #{inspect @page_defaults}

  `window` must be a positive non-zero integer or an exception is raised. `next` and `previous` should be
  strings but can be anything you want as long as it is truthy, falsey values will remove
  them from the output. `first` and `last` are only booleans, and they just include/remove
  their respective link from output. An example of the data returned:

      iex> Kerosene.HTML.raw_paginate(%{total_pages: 10, page: 5})
      [{"<<", 4}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9}, {10, 10}, {">>", 6}]

  Simply loop and pattern match over each item and transform it to your custom HTML.
  """
  def build_page_list(conn, paginator, options \\ []) do
    options = Keyword.merge(@page_defaults, options)

    paginator.page
      |> previous_page
      |> first_page(paginator.page, options[:window], options[:first])
      |> page_list(paginator.page, paginator.total_pages, options[:window])
      |> last_page(paginator.page, paginator.total_pages, options[:window], options[:last])
      |> next_page(paginator.page, paginator.total_pages)
      |> Enum.map(fn {label, page} -> {label, page, build_url(conn, page: page)} end)
  end

  defp render_page_list(page_list, paginator, [theme: :bootstrap, path: path, params: _params, opts: _opts]) do
    Kerosene.HTML.Boostrap.generate_links(page_list, paginator)
  end
  defp render_page_list(page_list, paginator, [theme: :foundation, path: path, params: _params, opts: _opts]) do
    Kerosene.HTML.Foundation.generate_links(page_list, paginator)
  end
  defp render_page_list(page_list, paginator, [theme: :semantic, path: path, params: _params, opts: _opts]) do
    Kerosene.HTML.Semantic.generate_links(page_list, paginator)
  end
  defp render_page_list(page_list, paginator, opts) do
    generate_links(page_list, paginator)
  end

  defp generate_links(page_list, paginator) do
    content_tag :nav, class: "pagination" do
      for {label, page, path} <- page_list do
        link "#{label}", to: path
      end
    end
  end

  # Computing page number ranges
  defp page_list(list, page, total, window) when is_integer(window) and window >= 1 do
    page_list = left(page, window)..right(page, total, window) |> Enum.map(fn n -> {n, n} end)
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
    Keyword.merge(@defaults, opts)
  end
end

# Must do this until Kerosene adds @derive [Enumerable, Access]
defimpl Enumerable, for: Kerosene do
  def reduce(pages, acc, fun), do: Enum.reduce(pages.items || [], acc, fun)
  def member?(pages, page), do: page in pages.items
  def count(pages), do: length(pages.items)
end
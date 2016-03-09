defmodule Kerosene.HTML do
  use Phoenix.HTML

  @defaults [theme: :bootstrap, action: :index]
  @themes [:bootstrap, :foundation, :semantic]
  @raw_defaults [distance: 5, next: "Next", previous: "Previous", first: true, last: true]

  @moduledoc """
  For use with Phoenix.HTML, configure the `:route_helpers` module like the following:

      config :kerosene,
        routes_helper: MyApp.Router.Helpers

  Import to you view.

      defmodule MyApp.UserView do
        use MyApp.Web, :view
        import Kerosene.HTML
      end

  Use in your template.

      <%= paginate @conn, @pages %>

  Where `@pages` is a `%Kerosene{}` struct returned from `Repo.paginate/2`.

  Customize output. Below are the defaults.
    <%= paginate @conn, @pages, distance: 5, next: ">>", previous: "<<", first: true, last: true %>

  See `Kerosene.HTML.raw_pagination_links/2` for option descriptions.

  For custom HTML output, see `Kerosene.HTML.raw_pagination_links/2`.
  """

  defmodule Default do
    @doc """
    Default path function when none provided. Used when automatic path function
    resolution cannot be performed.
    """
    def path(_conn, :index, opts) do
      Enum.reduce opts, "?", fn {k, v}, s ->
        "#{s}#{if(s == "?", do: "", else: "&")}#{k}=#{v}"
      end
    end
  end

  @doc """
  Generates the HTML pagination links for a given paginator returned by Kerosene.

  The default options are:

      #{inspect @defaults}

  The `theme` indicates which CSS framework you are using. The default is
  `:bootstrap`, but you can add your own using the `Kerosene.HTML.raw_pagination_links/2` function
  if desired. The full list of available `theme`s is here:

      #{inspect @themes}

  An example of the output data:

      iex> Kerosene.HTML.paginate(%Kerosene{total_pages: 10, page: 5})
      {:safe,
        ["<nav>",
         ["<ul class=\"pagination\">",
          [["<li>", ["<a class=\"\" href=\"?page=4\">", "&lt;&lt;", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=1\">", "1", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=2\">", "2", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=3\">", "3", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=4\">", "4", "</a>"], "</li>"],
           ["<li>", ["<a class=\"active\" href=\"?page=5\">", "5", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=6\">", "6", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=7\">", "7", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=8\">", "8", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=9\">", "9", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=10\">", "10", "</a>"], "</li>"],
           ["<li>", ["<a class=\"\" href=\"?page=6\">", "&gt;&gt;", "</a>"], "</li>"]],
          "</ul>"], "</nav>"]}

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
  defmacro __using__(opts \\ []) do
    quote do
      import Kerosene.HTML
    end
  end


  def paginate(conn, paginator, args, opts) do
    opts = Keyword.merge opts, theme: opts[:theme] || Application.get_env(:kerosene, :theme, :bootstrap)
    merged_opts = Keyword.merge @defaults, opts

    path = opts[:path] || find_path_fn(conn && paginator.items, args)
    params = Keyword.drop opts, (Keyword.keys(@defaults) ++ [:path])

    # Ensure ordering so pattern matching is reliable
    do_paginate paginator,
      theme: merged_opts[:theme],
      path: path,
      args: [conn, merged_opts[:action]] ++ args,
      params: params
  end
  def paginate(%Kerosene{} = paginator), do: paginate(nil, paginator, [], [])
  def paginate(%Kerosene{} = paginator, opts), do: paginate(nil, paginator, [], opts)
  def paginate(conn, %Kerosene{} = paginator), do: paginate(conn, paginator, [], [])
  def paginate(conn, paginator, [{_, _} | _] = opts), do: paginate(conn, paginator, [], opts)
  def paginate(conn, paginator, [_ | _] = args), do: paginate(conn, paginator, args, [])

  defp find_path_fn(nil, _path_args), do: &Default.path/3
  defp find_path_fn([], _path_args), do: fn _, _, _ -> nil end
  # Define a different version of `find_path_fn` whenever Phoenix is available.
  if Code.ensure_loaded(Phoenix.Naming) do
    defp find_path_fn(items, path_args) do
      route_helpers_module = Application.get_env(:kerosene, :route_helpers) || raise("Kerosene.HTML: Unable to find configured route_helpers module (ex. MyApp.Router.Helpers)")
      path = (path_args) |> Enum.reduce(name_for(List.first(items), ""), &name_for/2)
      {path_fn, []} = Code.eval_quoted(quote do: &unquote(route_helpers_module).unquote(:"#{path <> "_path"}")/unquote(length(path_args) + 3))
      path_fn
    end
  else
    defp find_path_fn(_items, _args), do: &Default/3
  end

  defp name_for(model, acc) do
    "#{acc}#{if(acc != "", do: "_")}#{Phoenix.Naming.resource_name(model.__struct__)}"
  end

  defp do_paginate(_paginator, [theme: style, path: _path, args: _args, params: _params]) when not style in @themes do
    raise "Kerosene.HTML: Theme #{inspect style} is not a valid them. Please use one of #{inspect @themes}"
  end

  # Bootstrap implementation
  defp do_paginate(paginator, [theme: :bootstrap, path: path, args: args, params: params]) do
    url_params = Keyword.drop params, Keyword.keys(@raw_defaults)
    content_tag :nav do
      content_tag :ul, class: "pagination" do
        raw_paginate(paginator, params)
        |> Enum.map(fn ({text, page})->
          classes = []
          if paginator.page == page do
            classes = ["active"]
          end
          params_with_page = Keyword.merge(url_params, page: page)
          content_tag :li, class: Enum.join(classes, " ") do
            to = apply(path, args ++ [params_with_page])
            if to do
              link "#{text}", to: to
            else
              content_tag :a, "#{text}"
            end
          end
        end)
      end
    end
  end

  # Semantic UI implementation
  defp do_paginate(paginator, [theme: :semantic, path: path, args: args, params: params]) do
    url_params = Keyword.drop params, Keyword.keys(@raw_defaults)
    content_tag :div, class: "ui pagination menu" do
      raw_paginate(paginator, params)
      |> Enum.map(fn({text, page}) ->
        classes = ["item"]
        if paginator.page == page do
          classes = ["active", "item"]
        end
        params_with_page = Keyword.merge(url_params, page: page)
        to = apply(path, args ++ [params_with_page])
        class = Enum.join(classes, " ")
        if to do
          link "#{text}", to: apply(path, args ++ [params_with_page]), class: class
        else
          content_tag :a, "#{text}", class: class
        end
      end)
    end
  end

  # Foundation for Sites 6.x implementation
  defp do_paginate(paginator, [theme: :foundation, path: path, args: args, params: params]) do
    url_params = Keyword.drop params, Keyword.keys(@raw_defaults)
    content_tag :ul, class: "pagination", role: "pagination" do
      raw_paginate(paginator, params)
      |> Enum.map(fn({text, page}) ->
        classes = []
        if paginator.page == page do
          classes = ["current"]
        end
        params_with_page = Keyword.merge(url_params, page: page)
        to = apply(path, args ++ [params_with_page])
        class = Enum.join(classes, " ")
        content_tag :li, class: class do
          if paginator.page == page do
            content_tag :span, "#{text}"
          else
            if to do
              link "#{text}", to: apply(path, args ++ [params_with_page])
            else
              content_tag :a, "#{text}"
            end
          end
        end
      end)
    end
  end

  @doc """
  Returns the raw data in order to generate the proper HTML for pagination links. Data
  is returned in a `{text, page}` format where `text` is intended to be the text
  of the link and `page` is the page it should go to. Defaults are already supplied
  and they are as follows:

      #{inspect @raw_defaults}

  `distance` must be a positive non-zero integer or an exception is raised. `next` and `previous` should be
  strings but can be anything you want as long as it is truthy, falsey values will remove
  them from the output. `first` and `last` are only booleans, and they just include/remove
  their respective link from output. An example of the data returned:

      iex> Kerosene.HTML.raw_paginate(%{total_pages: 10, page: 5})
      [{"<<", 4}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9}, {10, 10}, {">>", 6}]

  Simply loop and pattern match over each item and transform it to your custom HTML.
  """
  def raw_paginate(paginator, options \\ []) do
    options = Keyword.merge @raw_defaults, options

    add_previous(paginator.page)
    |> add_first(paginator.page, options[:distance], options[:first])
    |> page_list(paginator.page, paginator.total_pages, options[:distance])
    |> add_last(paginator.page, paginator.total_pages, options[:distance], options[:last])
    |> add_next(paginator.page, paginator.total_pages)
    |> Enum.map(fn
      :next -> if options[:next], do: {options[:next], paginator.page + 1}
      :previous -> if options[:previous], do: {options[:previous], paginator.page - 1}
      num -> {num, num}
    end) |> Enum.filter(&(&1))
  end

  # Computing page number ranges
  defp page_list(list, page, total, distance) when is_integer(distance) and distance >= 1 do
    list ++ Enum.to_list(beginning_distance(page, distance)..end_distance(page, total, distance))
  end
  defp page_list(_list, _page, _total, _distance) do
    raise "Kerosene.HTML: Distance cannot be less than one."
  end

  # Beginning distance computation
  defp beginning_distance(page, distance) when page - distance < 1 do
    page - (distance + (page - distance - 1))
  end
  defp beginning_distance(page, distance) do
    page - distance
  end

  # End distance computation
  defp end_distance(page, 0, _distance) do
    page
  end
  defp end_distance(page, total, distance) when page + distance >= total do
    total
  end
  defp end_distance(page, _total, distance) do
    page + distance
  end

  # Adding next/prev/first/last links
  defp add_previous(page) when page != 1 do
    [:previous]
  end
  defp add_previous(_page) do
    []
  end

  defp add_first(list, page, distance, true) when page - distance > 1 do
    [1 | list]
  end
  defp add_first(list, _page, _distance, _included) do
    list
  end

  defp add_last(list, page, total, distance, true) when page + distance < total do
    list ++ [total]
  end
  defp add_last(list, _page, _total, _distance, _included) do
    list
  end

  defp add_next(list, page, total) when page != total and page < total do
    list ++ [:next]
  end
  defp add_next(list, _page, _total) do
    list
  end

end

# Must do this until Kerosene adds @derive [Enumerable, Access]
defimpl Enumerable, for: Kerosene do
  def reduce(pages, acc, fun), do: Enum.reduce(pages.items || [], acc, fun)
  def member?(pages, page), do: page in pages.items
  def count(pages), do: length(pages.items)
end
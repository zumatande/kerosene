defmodule Kerosene.HTML do
  use Phoenix.HTML
  alias Kerosene.HTML
  import Kerosene.Paginator, only: [build_options: 2]

  @themes [:bootstrap, :bootstrap4, :foundation, :semantic]

  @moduledoc """
  Html helpers to render the pagination links and more,
  import the `Kerosene.HTML` in your view module.

      defmodule MyApp.ProductView do
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

  The `theme` indicates which CSS framework you are using. The default is
  `:bootstrap`, but you can add your own using the `Kerosene.HTML.do_paginate/3` function
  if desired. Kerosene provides few themes out of the box:

      #{inspect @themes}

  Example:

      iex> Kerosene.HTML.paginate(@conn, @kerosene)

  Path can be overriden by adding setting `:path` in the `opts`.
  For example:

      Kerosene.HTML.paginate(@conn, @kerosene, path: product_path(@conn, :index, foo: "bar"))
  """
  defmacro __using__(_opts \\ []) do
    quote do
      import Kerosene.HTML
    end
  end

  def paginate(conn, paginator, opts \\ []) do
    opts = build_options(conn, opts)

    conn 
    |> Kerosene.Paginator.paginate(paginator, opts) 
    |> render_page_list(opts)
  end

  defp render_page_list(page_list, opts) do
    case opts[:theme] do
      :bootstrap  -> HTML.Boostrap.generate_links(page_list)
      :bootstrap4 -> HTML.Boostrap4.generate_links(page_list)
      :foundation -> HTML.Foundation.generate_links(page_list)
      :semantic   -> HTML.Semantic.generate_links(page_list)
      _           -> HTML.Simple.generate_links(page_list)
    end
  end
end
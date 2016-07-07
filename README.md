# Kerosene

Pagination for Ecto and Phoenix.


## Installation

The package is [available in Hex](https://hex.pm/packages/kerosene), the package can be installed as:

  Add kerosene to your list of dependencies in `mix.exs`:

        def deps do
          [{:kerosene, "~> 0.2.0"}]
        end

  Add Kerosene to your `repo.ex`:

        defmodule MyApp.Repo do
          use Ecto.Repo, otp_app: :testapp
          use Kerosene, per_page: 2
        end

## Usage
  Start paginating your queries 

        def index(conn, params) do
          {products, kerosene} = 
          Product
          |> Product.with_lowest_price
          |> Repo.paginate(params)

          render(conn, "index.html", products: products, kerosene: kerosene)
        end

  Add view helpers to your view 

        defmodule MyApp.ProductView do
          use MyApp.Web, :view
          import Kerosene.HTML
        end

  Generate the links using the view helpers

        <%= paginate @conn, @kerosene %>

  Building apis or SPA's, no problem Kerosene has support for Json.

      defmodule MyApp.ProductView do
          use MyApp.Web, :view
          import Kerosene.JSON

          def render("index.json", %{products: products, kerosene: kerosene, conn: conn}) do
            %{data: render_many(products, MyApp.ProductView, "product.json"),
              pagination: paginate(conn, kerosene)}
          end

          def render("product.json", %{product: product}) do
            %{id: product.id,
              name: product.name,
              description: product.description,
              price: product.price}
          end
        end


  You can also send in options to paginate helper look at the docs for more details.

## Contributing
	
Please do send pull requests and bug reports, positive feedback is always welcome.


## Acknowledgement

I would like to Thank

    * Matt (@mgwidmann)
    * Drew Olson (@drewolson)
    * Akira Matsuda (@amatsuda)

## License

Please take a look at LICENSE.md

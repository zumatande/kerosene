# Kerosene

Pagination for Ecto and Phoenix.


## Installation

The package is [available in Hex](https://hex.pm/packages/kerosene), the package can be installed as:

  1. Add kerosene to your list of dependencies in `mix.exs`:

        def deps do
          [{:kerosene, "~> 0.1.0"}]
        end

  2. Add Kerosene to your `repo.ex`:

        defmodule MyApp.Repo do
          use Ecto.Repo, otp_app: :testapp
          use Kerosene, per_page: 2
        end

  3. You can start paginating your queries 

        def index(conn, params) do
          {products, kerosene} = 
          Product
          |> Product.with_lowest_price
          |> Repo.paginate(params)

          render(conn, "index.html", products: products, kerosene: kerosene)
        end

  4. Add view helpers to your view 

        defmodule MyApp.ProductView do
          use MyApp.Web, :view
          import Kerosene.HTML
        end

  5. Generate the links using the view helpers

        <%= paginate @conn, @kerosene %>

  Note: you can also send in opts for the helper look at the docs for more details

## Contributing
	
Please do send pull requests and bug reports, positive feedback is always welcome.


## Acknowledgement

I would like to Thank

    * Matt (@mgwidmann)
    * Drew Olson (@drewolson)
    * Akira Matsuda (@amatsuda)

## License

Please take a look at LICENSE.md

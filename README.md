# Kerosene

Pagination for Ecto and Phoenix.


## Installation

The package is [available in Hex](https://hex.pm/packages/kerosene), the package can be installed as:

  1. Add kerosene to your list of dependencies in `mix.exs`:

        def deps do
          [{:kerosene, "~> 0.1.0"}]
        end

  2. Add Kerosene to your `repo.ex`:

    defmodule Testapp.Repo do
		  use Ecto.Repo, otp_app: :testapp
		  use Kerosene, per_page: 2
		end

  3. You can start paginating your queries 

		def index(conn, params) do
    	  kerosene = Project
          |> Project.active
          |> Repo.paginate(params)

    	  render(conn, "index.html", projects: kerosene.items, page: kerosene)
  		end

  4. Add view helpers to your view 

  		defmodule MyApp.ProjectView do
        use MyApp.Web, :view
        import Kerosene.HTML
      end

  5. Generate the links using the view helpers

  		<%= paginate @conn, @page %>

  		Note: you can also send in opts for the helper look at the docs for more details

## Contributing
	
Please do send pull requests and bug reports, positive feedback is always welcome.


## Acknowledgements
I would like to Thanks

	* Matt (@mgwidmann)
	* Drew Olson (@drewolson)
	* Akira Matsuda (@amatsuda)
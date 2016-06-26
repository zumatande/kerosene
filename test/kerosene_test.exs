defmodule KeroseneTest do
  use ExUnit.Case
  import Ecto.Query
  alias Kerosene.Repo
  alias Kerosene.Product

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Kerosene.Repo)
  end

  defp create_products do
    for _ <- 1..10 do
      %Product { name: "Product 1", price: 100.00 }
      |> Repo.insert!
    end
  end

  test "foo is bar" do
    create_products

    kerosene = Product
      |> Repo.paginate

    IO.inspect(kerosene)
    # assert kerosene = %Kerosene {}
  end
end

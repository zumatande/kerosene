defmodule KeroseneTest do
  use ExUnit.Case
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

  test "returns set per_page" do
    create_products()
    {_items, kerosene} = Product |> Repo.paginate(%{}, per_page: 5)
    assert kerosene.per_page == 5
  end

  test "have total pages based on per_page" do
    create_products()
    {_items, kerosene} = Product |> Repo.paginate(%{}, per_page: 5)
    assert kerosene.total_pages == 2 
  end

  test "uses default config" do
    create_products()
    {_items, kerosene} = Product |> Repo.paginate(%{})
    assert kerosene.total_pages == 1 
    assert kerosene.page == 1
  end

  test "work out total pages" do
    row_count = 100
    per_page = 10
    total_pages = 10
    assert Kerosene.get_total_pages(row_count, per_page) == total_pages
  end

  test "return integer from binary" do
    assert Kerosene.to_integer("100") == 100
    assert Kerosene.to_integer(10) == 10
    assert Kerosene.to_integer(nil) == 1
  end
end

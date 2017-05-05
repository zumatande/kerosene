defmodule Kerosene.Product do
  use Ecto.Schema

  schema "products" do
    field :name, :string
    field :price, :decimal
    field :orders_count, :integer, virtual: :true
    timestamps()

    has_many :orders, Kerosene.Order
  end
end

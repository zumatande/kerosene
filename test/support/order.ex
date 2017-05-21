defmodule Kerosene.Order do
  use Ecto.Schema

  schema "orders" do
    belongs_to :product, Kerosene.Product
  end
end

defmodule Kerosene.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :product_id, references(:products, on_delete: :nilify_all)
    end
  end
end

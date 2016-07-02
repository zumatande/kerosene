defmodule HTMLRenderersInputData do
  def page_list() do
    [
      {"First", 1, "/products?category=25&page=1"},
      {"<", 6, "/products?category=25&page=6"},
      {2, 2, "/products?category=25&page=2"},
      {3, 3, "/products?category=25&page=3"},
      {4, 4, "/products?category=25&page=4"},
      {5, 5, "/products?category=25&page=5"},
      {6, 6, "/products?category=25&page=6"},
      {7, 7, "/products?category=25&page=7"},
      {8, 8, "/products?category=25&page=8"},
      {9, 9, "/products?category=25&page=9"},
      {10, 10, "/products?category=25&page=10"},
      {11, 11, "/products?category=25&page=11"},
      {12, 12, "/products?category=25&page=12"},
      {">", 8, "/products?category=25&page=8"},
      {"Last", 16, "/products?category=25&page=16"}
    ]
  end

  def paginator() do
    %Kerosene{
      items: [],
      page: 7,
      params: [category: "25", page: "7"],
      per_page: 20,
      total_count: 305,
      total_pages: 16
    }
  end
end

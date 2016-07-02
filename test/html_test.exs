defmodule Kerosene.HTMLTest do
  use ExUnit.Case, async: true
  import Kerosene.HTML

  test "next page only if there are more pages" do
    assert next_page([], 10, 10) == []
    assert next_page([{:previous, 9}], 10, 10) == [{:previous, 9}]
    assert next_page([], 10, 12) == [{:next, 11}]
  end

  test "generate previous page unless first" do
    assert previous_page(0) == []
    assert previous_page(10) == [{:previous, 9}]
  end

  test "generate first page" do
    page = 5
    lower_page = 3
    window = 3
    show_first = true
    assert first_page([], page, window, show_first) == [{:first, 1}]
    assert first_page([], page, window, not show_first) == []
    assert first_page([], lower_page, window, show_first) == []
  end

  test "generate last page" do
    total = 10
    page = 2
    higher_page = 5
    window = 3
    show_last = true
    assert last_page([], page, total, window, show_last) == [{:last, 10}]
    assert last_page([], page, total, window, not show_last) == []
    assert last_page([], higher_page, total, window, not show_last) == []
  end

  test "encode query params" do
    params = [query: "foo", page: 2, per_page: 10]
    expected = "query=foo&page=2&per_page=10"

    assert build_query(params) == expected
  end

  test "build full abs url with params" do
    params = [query: "foo", page: 2, per_page: 10]
    expected = "http://localhost:4000/products?query=foo&page=2&per_page=10"
    conn = %{request_path: "http://localhost:4000/products"}
    assert build_url(conn, params) == expected

  end
end

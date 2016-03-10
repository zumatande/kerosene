defmodule Kerosene.HTML.Semantic do
  use Phoenix.HTML

  def generate_links(page_list, paginator) do
    content_tag :nav, class: "ui pagination menu" do
      for {label, page, path} <- page_list do
          link "#{label}", to: path, class: build_html_class(paginator, page)
      end
    end
  end

  defp build_html_class(paginator, page) do
    if paginator.page == page do
      "item active"
    else
      "item"
    end
  end

end
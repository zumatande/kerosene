defmodule Kerosene.HTML.Foundation do
  use Phoenix.HTML

  def generate_links(page_list, paginator) do
    content_tag :ul, class: "pagination", role: "pagination" do
      for {label, page, path} <- page_list do
        content_tag :li, class: build_html_class(paginator, page) do
          link "#{label}", to: path
        end
      end
    end
  end

  defp build_html_class(paginator, page) do
    if paginator.page == page do
      "active"
    else
      " "
    end
  end

end
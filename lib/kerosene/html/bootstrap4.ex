defmodule Kerosene.HTML.Boostrap4 do
  use Phoenix.HTML

  def generate_links(page_list) do
    content_tag :nav do
      content_tag :ul, class: "pagination" do
        for {label, _page, path, active} <- page_list do
          content_tag :li, class: build_html_class(active) do
            link "#{label}", to: path, class: "page-link"
          end
        end
      end
    end
  end

  defp build_html_class(true), do: "page-item active"
  defp build_html_class(_), do: "page-item"
end

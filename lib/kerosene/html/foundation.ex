defmodule Kerosene.HTML.Foundation do
  use Phoenix.HTML

  def generate_links(page_list) do
    content_tag :ul, class: "pagination", role: "pagination" do
      for {label, _page, url, current} <- page_list do
        content_tag :li, class: build_html_class(current) do
          link "#{label}", to: url
        end
      end
    end
  end

  defp build_html_class(true), do: "active"
  defp build_html_class(_), do: nil
end

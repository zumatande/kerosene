defmodule Kerosene.HTML.Simple do
  use Phoenix.HTML

  def generate_links(page_list) do
    content_tag :nav, class: "pagination" do
      for {label, _page, path, active} <- page_list do
        link "#{label}", to: path, class: build_html_class(active)
      end
    end
  end

  defp build_html_class(true), do: "active"
  defp build_html_class(_), do: nil
end

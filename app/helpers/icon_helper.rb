module IconHelper
  def d_icon(name, css: "")
    render "decidim/icons/#{name}", class: css
  end
end
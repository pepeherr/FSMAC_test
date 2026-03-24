# config/initializers/tree/tree_menu.rb
Rails.application.config.to_prepare do
  Decidim.view_hooks.register(
    "decidim.header.menu",
    priority: 50
  ) do
    render partial: "decidim/tree/tree_menu"
    Rails.logger.debug "TREE menu HOOK LOADED"
  end
end
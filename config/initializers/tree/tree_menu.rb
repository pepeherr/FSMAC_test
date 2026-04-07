# config/initializers/tree/tree_menu.rb
Rails.application.config.to_prepare do
  # Añade elemento tree en el menú móvil
  # Inserta con prepend el helper /home/layla/FSMAC_test/app/helpers/decidim/menu_helper_decorator.rb
  # antes del original permitiendo super
  Rails.logger.debug "TREE MENU INJECTADO"
  # Añade elemento tree en el menú ordenador
  Decidim.view_hooks.register(
    "decidim.header.menu",
    priority: 50
  ) do
    render partial: "decidim/tree/tree_menu"
    Rails.logger.debug "TREE menu HOOK LOADED"
  end
end

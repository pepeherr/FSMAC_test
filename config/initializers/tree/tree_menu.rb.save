# config/initializers/tree/tree_menu.rb
# frozen_string_literal: true

Rails.application.config.to_prepare do
  # Verificar que el menú navbar existe antes de modificarlo
  if Decidim.menu_registry.any? { |m| m.name == :navbar }
    Decidim.menu :navbar do |menu|
      menu.item I18n.t("menu.arbol", default: "🌳 Árbol"),
                main_app.arbol_path,
                position: 50,
                active: :inclusive,
                icon_name: "organization",
                if: Proc.new { |user| user&.admin? || user&.can_be_contacted? }
    end
  else
    Rails.logger.warn "Menú navbar no encontrado - el árbol no se añadió al menú"
  end
end
# config/initializers/fsmac_component_extension.rb
# Asignamos el rol a las Proposals dependientes y distinguirlas:
# Proposal Necesidad: need
Rails.application.config.to_prepare do
  Decidim::Component.class_eval do
    enum fsmac_role: {
      need: "need",
      action: "action"
    }

    def fsmac_action?
      fsmac_role == :action
    end

    def fsmac_need?
      fsmac_role == :need
    end

  end
end
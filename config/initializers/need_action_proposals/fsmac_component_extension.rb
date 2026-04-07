# config/initializers/fsmac_component_extension.rb
# Asignamos el rol a las Proposals dependientes y distinguirlas:
# Proposal Necesidad: need
Rails.application.config.to_prepare do
  # inicializa el semáforo en app/controllers/concerns/action_helper.rb
  Decidim::ApplicationController.include(ActionHelper)

  Decidim::Component.class_eval do
    enum fsmac_role: {
      need: "need",
      action: "action"
    }

    def fsmac_action?
      action?
    end

    def fsmac_need?
      need?
    end
  end
end

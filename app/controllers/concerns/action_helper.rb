# app/controllers/concerns/action_helper.rb
# este helper es inicializado desde config/initializers/need_action_proposals/fsmac_component_extension.rb
# con Decidim::ApplicationController.include(ActionHelper)
# Establece una condición en las vistas incluidas en app/views/decidim/proposals para mostrar o no las
# propuestas fsmac_action (fsmac_role = action)
module ActionHelper
  extend ActiveSupport::Concern

  included do
    helper_method :semaforo?
  end

  def semaforo?
    true
  end
end

#config/initializer/decidim_proposal_controller_extension.rb
#Permitir el parámetro en el controller
#permitir guardar el campo

Rails.application.config.to_prepare do
    next unless defined?(Decidim::Proposals::ProposalsController)
	Decidim::Proposals::ProposalsController.class_eval do
		private
		def proposal_params
			super.merge(parent_objective_id: params.dig(:proposal, :parent_objective_id))
		end
	end
end
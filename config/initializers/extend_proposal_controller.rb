#config/initializers/extend_proposal_controller.rb

Rails.application.config.to_prepare do
  Decidim::Proposals::ProposalsController.class_eval do
    private

    def permitted_params
      super.merge(
        proposal: super[:proposal].merge(
          parent_objective_id: params.dig(:proposal, :parent_objective_id)
        )
      )
    end
  end
end
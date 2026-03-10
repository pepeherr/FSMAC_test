# config/initializers/decidim_create_proposal_extension.rb

Rails.application.config.to_prepare do
  next unless defined?(Decidim::Proposals::CreateProposal)

  Decidim::Proposals::CreateProposal.class_eval do
    alias_method :original_create_proposal, :create_proposal

    private

    def create_proposal
      original_create_proposal
      # Solo para componente Acciones
      if form.component.fsmac_action? && form.parent_objective_id.present?
        # proposal.update_column(:parent_objective_id, form.parent_objective_id)
        @proposal.update(
          parent_objective_id: form.parent_objective_id.to_i
        )
      end
    end
  end
end

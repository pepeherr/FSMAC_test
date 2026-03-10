# config/initializers/need_action_proposals/fsmac_proposal_redirect.rb
Rails.application.config.to_prepare do
  next unless defined?(Decidim::Proposals::ProposalsController)

  Decidim::Proposals::ProposalsController.class_eval do
    alias_method :original_create, :create

    def create
      original_create

      return unless @proposal&.persisted?
      return unless current_component.fsmac_action?
      return if @proposal.parent_objective_id.blank?

      parent = Decidim::Proposals::Proposal.find_by(id: @proposal.parent_objective_id)
      return unless parent

      redirect_to resource_locator(parent).path
    end
  end
end
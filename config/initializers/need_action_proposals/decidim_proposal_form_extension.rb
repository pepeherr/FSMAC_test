# config/initializers/decidim_proposal_form_extension.rb
# Decorar el formulario:
# Esto permite que el formulario acepte el nuevo campo.

Rails.application.config.to_prepare do
  next unless defined?(Decidim::Proposals::ProposalForm)

  Decidim::Proposals::ProposalForm.class_eval do
    attribute :parent_objective_id, Integer
  end
end

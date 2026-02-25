#config/initializars/decidim_proposal_extension.rb
# child_actions → una necesidad (propuesta) puede tener muchas acciones hijas.
# parent_objective → una acción puede tener una necesidad madre
# optional: true → permite que existan necesidades sin padre (necesidades raíz)
# Con nullify si borras un objetivo, las acciones no
#      desaparecen; simplemente quedan sin padre (más seguro)
# defined? evita que se ejecute antes de que el engine cargue.

Rails.application.config.to_prepare do
   next unless defined?(Decidim::Proposals::Proposal)
      Decidim::Proposals::Proposal.class_eval do
         belongs_to :parent_objective,
            class_name: "Decidim::Proposals::Proposal",
            optional: true
         has_many :child_actions,
            class_name: "Decidim::Proposals::Proposal",
            foreign_key: :parent_objective_id,
            dependent: :nullify
      end
end

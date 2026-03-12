# app/models/concerns/fsmac/fsmac_methods.rb
module Fsmac
  module FsmacMethods
    extend ActiveSupport::Concern

    def needs
      Decidim::Proposals::Proposal
        .joins(:component)
        .where(decidim_components: {
          participatory_space_id: id,
          participatory_space_type: "Decidim::ParticipatoryProcess",
          fsmac_role: "need"
        })
    end
  end
end

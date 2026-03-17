# config/initializers/process/fsmac_participatory_process_patch.rb

Rails.application.config.to_prepare do
  # Patch para ParticipatoryProcess
  Decidim::ParticipatoryProcess.class_eval do
    belongs_to :assembly,
               class_name: "Decidim::Assembly",
               foreign_key: "parent_assembly_id",
               optional: true
  end

end
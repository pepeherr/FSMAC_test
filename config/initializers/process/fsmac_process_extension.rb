# config/initializers/process/fsmac_process_extension.rb
# Inicializa Fsmac::FsmacMethods incluida en app/models/concerns/fsmac/fsmac_methods.rb
Rails.application.config.to_prepare do
  Decidim::ParticipatoryProcess.include Fsmac::FsmacMethods
end
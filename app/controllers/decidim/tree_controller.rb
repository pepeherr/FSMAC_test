# app/controllers/decidim/tree_controller.rb
# frozen_string_literal: true

module Decidim

  class TreeController < Decidim::ApplicationController

    helper_method :titulo_objeto,
                  :enlace_objeto,
                  :icono_objeto,
                  :nombre_organizacion,
                  :proposals_hijas,
                  :mostrar_componente_proposals?

    def index
      @organization = current_organization
      @locale = params[:locale] || I18n.locale
      @org_id = @organization.id

      cargar_datos_tree
      render "decidim/tree/index"
    end

    def nombre_organizacion
      org = current_organization
      locale = params[:locale] || I18n.locale
      org.name[locale.to_s] || org.name["es"] || org.name["en"] || org.name.values.first || "Organización"
    end

    private

    def cargar_datos_tree

    #Configuración del arbol

      @mostrar_id = false

      # Asambleas y procesos de la organización publicadas y públicas
      @asambleas = Decidim::Assembly
                   .published
                   .where(decidim_organization_id: @org_id)
                   .where(private_space: false)
                   .includes(:parent)
                   .order(:parent_id, :id)

      @procesos = Decidim::ParticipatoryProcess
                  .published
                  .where(decidim_organization_id: @org_id)
                  .order(:parent_assembly_id, :id)

      @procesos_por_asamblea = @procesos.group_by(&:parent_assembly_id)

      @comps_assembly = Decidim::Component
                        .where(participatory_space_type: "Decidim::Assembly")
                        .where(participatory_space_id: @asambleas.pluck(:id))
                        .group_by(&:participatory_space_id)

      @comps_process = Decidim::Component
                       .where(participatory_space_type: "Decidim::ParticipatoryProcess")
                       .where(participatory_space_id: @procesos.pluck(:id))
                       .group_by(&:participatory_space_id)

      component_ids_proposals = Decidim::Component
                                .where(participatory_space_type: ["Decidim::Assembly", "Decidim::ParticipatoryProcess"])
                                .where(participatory_space_id: @asambleas.pluck(:id) + @procesos.pluck(:id))
                                .where(manifest_name: "proposals")
                                .pluck(:id)

      @todas_proposals = []
      if component_ids_proposals.any?
        @todas_proposals = Decidim::Proposals::Proposal
                           .where(decidim_component_id: component_ids_proposals)
                           .select(:id, :title, :parent_objective_id, :decidim_component_id)
                           .to_a
      end

      # ÍNDICE GLOBAL: Todas las propuestas indexadas por ID (para búsqueda rápida)
      @proposals_por_id = @todas_proposals.index_by(&:id)

      # Propuestas agrupadas por componente (para filtrar por espacio)
      @proposals_por_componente = @todas_proposals.group_by(&:decidim_component_id)

      @proposals_por_componente = @todas_proposals.group_by(&:decidim_component_id)
      @asambleas_raiz = @asambleas.select { |a| a.parent_id.nil? }

      Rails.logger.debug "=" * 50
      Rails.logger.debug "Total proposals: #{@todas_proposals.size}"
      Rails.logger.debug "Componentes con proposals: #{@proposals_por_componente.keys.join(', ')}"
      @proposals_por_componente.each do |comp_id, props|
        Rails.logger.debug "  Componente #{comp_id}: #{props.size} proposals"
        raices = props.select { |p| p.parent_objective_id.nil? }.size
        hijas = props.select { |p| p.parent_objective_id.present? }.size
        Rails.logger.debug "    Raíces: #{raices}, Hijas: #{hijas}"
      end
    end

    def titulo_objeto(objeto, defecto = "SIN TÍTULO")
      return defecto unless objeto&.respond_to?(:title)
      
      locale = @locale.to_s
      
      if objeto.is_a?(Decidim::Proposals::Proposal)
        if objeto.title.is_a?(Hash)
          objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || objeto.title.values.first || defecto
        else
          objeto.title.presence || defecto
        end
      else
        objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || defecto
      end
    end
    
    # Rutas
    def enlace_objeto(objeto)
      return "#" unless objeto
      
      case objeto.class.name
      when "Decidim::Assembly"
        "/assemblies/#{objeto.slug}"
      when "Decidim::ParticipatoryProcess"
        "/processes/#{objeto.slug}"
      when "Decidim::Component"
        if objeto.participatory_space.is_a?(Decidim::Assembly)
          "/assemblies/#{objeto.participatory_space.slug}/f/#{objeto.id}"
        else
          "/processes/#{objeto.participatory_space.slug}/f/#{objeto.id}"
        end
      when "Decidim::Proposals::Proposal"
        begin
          componente = Decidim::Component.find(objeto.decidim_component_id)
          if componente.participatory_space.is_a?(Decidim::Assembly)
            "/assemblies/#{componente.participatory_space.slug}/f/#{componente.id}/proposals/#{objeto.id}"
          else
            "/processes/#{componente.participatory_space.slug}/f/#{componente.id}/proposals/#{objeto.id}"
          end
        rescue
          "#"
        end
      else
        "#"
      end
    end
    
    def icono_objeto(objeto)
      case objeto.class.name
      when "Decidim::Assembly"
        "🏛️"
      when "Decidim::ParticipatoryProcess"
        "🔥"
      when "Decidim::Component"
        "🔧"
      when "Decidim::Proposals::Proposal"
        "📄"
      else
        "📌"
      end
    end

    # Helper para encontrar propuestas hijas (buscando en TODOS los componentes)
    def proposals_hijas(madre_id)
      return [] unless madre_id
      @todas_proposals.select { |p| p.parent_objective_id == madre_id }
    end

    # Helper para determinar si un componente de propuestas debe mostrarse en el nivel 1
    def mostrar_componente_proposals?(componente_id)
      if Decidim::Component.exists?(componente_id)
        a = Decidim::Component.find(componente_id)
        return true unless a.manifest_name == 'proposals' && a.fsmac_action?
      end
      false
    end
  end
end
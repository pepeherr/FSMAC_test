def arbol(org_id = 2, locale = "es")
  org = Decidim::Organization.find(org_id)
  nombre_org = org.name[locale] || org.name["es"] || org.name["en"] || "Organización #{org_id}"

  # Determinar URL base según entorno
  url_base = if Rails.env.production?
               "https://" & org.host
             else
               "http://127.0.0.1:3000"
             end

  puts "\n📌 #{nombre_org} (ID: #{org_id}) - #{url_base}"
  puts "=" * 120

  # Cargar todas las asambleas
  asambleas = Decidim::Assembly
              .where(decidim_organization_id: org_id)
              .includes(:parent)
              .order(:parent_id, :id)

  # Cargar todos los procesos
  procesos = Decidim::ParticipatoryProcess
             .where(decidim_organization_id: org_id)
             .order(:parent_assembly_id, :id)

  # Agrupar procesos por parent_assembly_id
  procesos_por_asamblea = procesos.group_by(&:parent_assembly_id)

  # Componentes de asambleas
  comps_assembly = Decidim::Component
                   .where(participatory_space_type: "Decidim::Assembly")
                   .where(participatory_space_id: asambleas.pluck(:id))
                   .group_by(&:participatory_space_id)

  # Componentes de procesos
  comps_process = Decidim::Component
                  .where(participatory_space_type: "Decidim::ParticipatoryProcess")
                  .where(participatory_space_id: procesos.pluck(:id))
                  .group_by(&:participatory_space_id)

  # PROPOSALS - Cargar todas las proposals
  component_ids_proposals = Decidim::Component
                            .where(participatory_space_type: ["Decidim::Assembly", "Decidim::ParticipatoryProcess"])
                            .where(participatory_space_id: asambleas.pluck(:id) + procesos.pluck(:id))
                            .where(manifest_name: "proposals")
                            .pluck(:id)

  todas_proposals = []
  if component_ids_proposals.any?
    todas_proposals = Decidim::Proposals::Proposal
                      .where(decidim_component_id: component_ids_proposals)
                      .select(:id, :title, :parent_objective_id, :decidim_component_id)
                      .to_a
  end

  proposals_por_componente = todas_proposals.group_by(&:decidim_component_id)
  proposals_por_id = todas_proposals.index_by(&:id)

  # Lambda para generar enlaces
  enlace = ->(objeto) {
    case objeto.class.name
    when "Decidim::Assembly"
      "#{url_base}/assemblies/#{objeto.slug}"
    when "Decidim::ParticipatoryProcess"
      "#{url_base}/processes/#{objeto.slug}"
    when "Decidim::Component"
      if objeto.participatory_space.is_a?(Decidim::Assembly)
        "#{url_base}/assemblies/#{objeto.participatory_space.slug}/f/#{objeto.id}"
      else
        "#{url_base}/processes/#{objeto.participatory_space.slug}/f/#{objeto.id}"
      end
    when "Decidim::Proposals::Proposal"
      componente = Decidim::Component.find(objeto.decidim_component_id)
      if componente.participatory_space.is_a?(Decidim::Assembly)
        "#{url_base}/assemblies/#{componente.participatory_space.slug}/f/#{componente.id}/proposals/#{objeto.id}"
      else
        "#{url_base}/processes/#{componente.participatory_space.slug}/f/#{componente.id}/proposals/#{objeto.id}"
      end
    else
      "#"
    end
  }

  # Función lambda para obtener título con enlace
  titulo_con_enlace = ->(objeto, defecto = "SIN TÍTULO") {
    titulo_texto = if objeto.is_a?(Decidim::Proposals::Proposal)
                     if objeto.title.is_a?(Hash)
                       objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || objeto.title.values.first || defecto
                     else
                       objeto.title.presence || defecto
                     end
                   else
                     objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || defecto
                   end

    url = enlace.call(objeto)
    "\e]8;;#{url}\e\\#{titulo_texto}\e]8;;\e\\" # Código ANSI para hipervínculo en terminal
  }

  # Función lambda para obtener título plano
  # (PODEMOS ELIMINARLO)
  titulo_plano = ->(objeto, defecto = "SIN TÍTULO") {
    if objeto.is_a?(Decidim::Proposals::Proposal)
      if objeto.title.is_a?(Hash)
        objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || objeto.title.values.first || defecto
      else
        objeto.title.presence || defecto
      end
    else
      objeto.title[locale] || objeto.title["es"] || objeto.title["en"] || defecto
    end
  }


  # Función para imprimir componentes (usando titulo_con_enlace)
  print_componentes = ->(componentes, sangria, prefijo_base = "   ") {

    return unless componentes && componentes.any?

    componentes.each_with_index do |comp, idx|
      es_ultimo = idx == componentes.size - 1
      nombre = comp.name[locale] || comp.name["es"] || comp.name["en"] || comp.manifest_name
      nombre_con_enlace = "\e]8;;#{enlace.call(comp)}\e\\#{nombre}\e]8;;\e\\"
      puts "#{sangria}#{prefijo_base}#{es_ultimo ? '└─ ' : '├─ '}🔧 #{nombre_con_enlace} (#{comp.manifest_name}, ID: #{comp.id})"

      if comp.manifest_name == "proposals" && proposals_por_componente[comp.id]&.any?
        proposals_del_componente = proposals_por_componente[comp.id]
        proposals_raiz = proposals_del_componente.select { |p| p.parent_objective_id.nil? }

        if proposals_raiz.any?
          sangria_proposals = "#{sangria}#{prefijo_base}#{es_ultimo ? '   ' : '│  '}"
          proposals_raiz.each_with_index do |proposal, p_idx|
            es_ultima_proposal = p_idx == proposals_raiz.size - 1
            titulo_proposal = titulo_con_enlace.call(proposal)
            puts "#{sangria_proposals}#{es_ultima_proposal ? '   └─ ' : '   ├─ '}📄 #{titulo_proposal} (ID: #{proposal.id})"

            print_proposals_hijas(proposal.id, proposals_del_componente, proposals_por_id, titulo_con_enlace, 
                                 sangria_proposals, es_ultima_proposal ? '   ' : '│  ')
          end
        end
      end
    end
  }


  # Función recursiva para imprimir el árbol (con enlaces)
  print_nodo = ->(nodo, nivel, es_ultimo, sangria_acum = "") {
    prefijo = nivel.zero? ? (es_ultimo ? "└─ " : "├─ ") : (es_ultimo ? "└─ " : "├─ ")

    titulo_nodo = titulo_con_enlace.call(nodo)
    puts "#{sangria_acum}#{prefijo}🏛️  #{titulo_nodo} (ID: #{nodo.id})"

    sangria_hijos = "#{sangria_acum}#{es_ultimo ? '   ' : '│  '}"
    
    if comps_assembly[nodo.id]&.any?
      print_componentes.call(comps_assembly[nodo.id], sangria_hijos, "   ")
    end

    if procesos_por_asamblea[nodo.id]&.any?
      procesos_por_asamblea[nodo.id].each_with_index do |proceso, idx|
        es_ultimo_proceso = idx == procesos_por_asamblea[nodo.id].size - 1
        sangria_proceso = "#{sangria_hijos}#{es_ultimo_proceso ? '   ' : '│  '}"

        titulo_proceso = titulo_con_enlace.call(proceso)
        puts "#{sangria_hijos}#{es_ultimo_proceso ? '└─ ' : '├─ '}🔥 #{titulo_proceso} (ID: #{proceso.id})"

        if comps_process[proceso.id]&.any?
          print_componentes.call(comps_process[proceso.id], sangria_proceso, "   ")
        end
      end
    end

    hijas = asambleas.select { |a| a.parent_id == nodo.id }

    hijas.each_with_index do |hija, idx|
      es_ultima_hija = idx == hijas.size - 1
      print_nodo.call(hija, nivel + 1, es_ultima_hija, sangria_hijos)
    end
  }

  # Empezar por asambleas raíz
  asambleas_raiz = asambleas.select { |a| a.parent_id.nil? }

  if asambleas_raiz.any?
    asambleas_raiz.each_with_index do |raiz, idx|
      print_nodo.call(raiz, 0, idx == asambleas_raiz.size - 1)
    end
  else
    puts "   ⚠️  No hay asambleas en esta organización"
  end
  
  # Procesos sin asamblea
  procesos_sin_asamblea = procesos_por_asamblea[nil]
  
  if procesos_sin_asamblea&.any?
    puts "\n   📋 CONFLICTOS SIN CIRCULO ASIGNADO:"
    procesos_sin_asamblea.each_with_index do |proceso, idx|
      es_ultimo = idx == procesos_sin_asamblea.size - 1
      prefijo = es_ultimo ? "   └─ " : "   ├─ "
      sangria_proceso = es_ultimo ? "      " : "   │  "

      titulo_proceso = titulo_con_enlace.call(proceso)
      puts "#{prefijo}🔥 #{titulo_proceso} (ID: #{proceso.id})"

      if comps_process[proceso.id]&.any?
        print_componentes.call(comps_process[proceso.id], sangria_proceso, "   ")
      end
    end
  end

  puts "\n" + "=" * 120
  
  # Estadísticas (usando títulos planos para no saturar)
  total_asambleas = asambleas.size
  total_procesos = procesos.size
  total_componentes = comps_assembly.values.flatten.size + comps_process.values.flatten.size
  total_proposals = todas_proposals.size
  
  proposals_con_hijas = 0
  if todas_proposals.any?
    proposals_con_hijas = todas_proposals.count { |p| todas_proposals.any? { |h| h.parent_objective_id == p.id } }
  end
  
  procesos_con_asamblea = procesos.count { |p| p.parent_assembly_id.present? }
  procesos_sin_asamblea_count = procesos.count { |p| p.parent_assembly_id.nil? }
  
  puts "📊 ESTADÍSTICAS:"
  puts "   🏛️ Circulos: #{total_asambleas}"
  puts "   🔥 Conflictos: #{total_procesos}"
  puts "      ├─ Con círculo: #{procesos_con_asamblea}"
  puts "      └─ Sin círculo: #{procesos_sin_asamblea_count}"
  puts "   🔧 Componentes: #{total_componentes}"
  puts "   📄 Propuestas: #{total_proposals}"
  
  if total_proposals > 0
    proposals_raiz = todas_proposals.count { |p| p.parent_objective_id.nil? }
    proposals_con_madre = todas_proposals.count { |p| p.parent_objective_id.present? }
    
    puts "      ├─ Raíces (sin madre): #{proposals_raiz}"
    puts "      ├─ Con madre: #{proposals_con_madre}"
    puts "      └─ Con hijas: #{proposals_con_hijas}"
  end
end

def print_proposals_hijas(madre_id, todas_proposals_del_componente, proposals_por_id, titulo_con_enlace, sangria_base, prefijo_extra)
  hijas = todas_proposals_del_componente.select { |p| p.parent_objective_id == madre_id }
  # Método recursivo para imprimir proposals hijas (con enlaces)
  hijas.each_with_index do |hija, idx|
    es_ultima_hija = idx == hijas.size - 1
    titulo_hija = titulo_con_enlace.call(hija)
    puts "#{sangria_base}#{prefijo_extra}#{es_ultima_hija ? '   └─ ' : '   ├─ '}📄 #{titulo_hija} (ID: #{hija.id})"

    print_proposals_hijas(hija.id, todas_proposals_del_componente, proposals_por_id, titulo_con_enlace, 
                          "#{sangria_base}#{prefijo_extra}", 
                          es_ultima_hija ? '   ' : '│  ')
  end
end

########## MAIN #######

arbo,l
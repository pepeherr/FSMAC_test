def arbol_final(org_id = 2, locale = "es")
  org = Decidim::Organization.find(org_id)
  nombre_org = org.name[locale]

  puts "\n📌 #{nombre_org} (ID: #{org_id})"
  puts "─" * 120

  # Cargar todas las asambleas (Círculos)
  asambleas = Decidim::Assembly
              .where(decidim_organization_id: org_id)
              .includes(:parent)
              .order(:parent_id, :id)

  # Cargar todos los procesos (Conflictos)
  procesos = Decidim::ParticipatoryProcess
             .where(decidim_organization_id: org_id)
             .order(:parent_assembly_id, :id)

  # Agrupar Conflictos por parent_assembly_id (Círculo padre)
  procesos_por_asamblea = procesos.group_by(&:parent_assembly_id)

  # Componentes de Circulos
  comps_assembly = Decidim::Component
                   .where(participatory_space_type: "Decidim::Assembly")
                   .where(participatory_space_id: asambleas.pluck(:id))
                   .group_by(&:participatory_space_id)

  # Componentes de Conflictos
  comps_process = Decidim::Component
                  .where(participatory_space_type: "Decidim::ParticipatoryProcess")
                  .where(participatory_space_id: procesos.pluck(:id))
                  .group_by(&:participatory_space_id)

  # PROPOSALS - Cargar todas los Conflictos
  component_ids_proposals = Decidim::Component
                            .where(participatory_space_type: ["Decidim::Assembly", "Decidim::ParticipatoryProcess"])
                            .where(participatory_space_id: asambleas.pluck(:id) + procesos.pluck(:id))
                            .where(manifest_name: "proposals")
                            .pluck(:id)

  # Cargar proposals
  todas_proposals = []
  if component_ids_proposals.any?
    todas_proposals = Decidim::Proposals::Proposal
                      .where(decidim_component_id: component_ids_proposals)
                      .select(:id, :title, :parent_objective_id, :decidim_component_id)
                      .to_a # Convertir a array para evitar consultas adicionales
  end

  proposals_por_componente = todas_proposals.group_by(&:decidim_component_id)
  proposals_por_id = todas_proposals.index_by(&:id)

  # Función auxiliar para obtener título
  titulo = ->(objeto, defecto = "SIN TÍTULO") {
    return defecto unless objeto&.respond_to?(:title)

    if objeto.is_a?(Decidim::Proposals::Proposal)
      if objeto.title.is_a?(Hash)
        objeto.title[locale] || objeto.title.values.first || defecto
      else
        objeto.title.presence || defecto
      end
    else
      objeto.title[locale] || defecto
    end
  }

  # Función para imprimir componentes
  print_componentes = ->(componentes, sangria, prefijo_base = "   ") {
    return unless componentes && componentes.any?
    componentes.each_with_index do |comp, idx|
      es_ultimo = idx == componentes.size - 1
      nombre = comp.name[locale] || comp.manifest_name
      puts "#{sangria}#{prefijo_base}#{es_ultimo ? '└─ ' : '├─ '}🔧 #{nombre} (#{comp.manifest_name}, ID: #{comp.id})"

      if comp.manifest_name == "proposals" && proposals_por_componente[comp.id]&.any?
        proposals_del_componente = proposals_por_componente[comp.id]
        proposals_raiz = proposals_del_componente.select { |p| p.parent_objective_id.nil? }
        
        if proposals_raiz.any?
          sangria_proposals = "#{sangria}#{prefijo_base}#{es_ultimo ? '   ' : '│  '}"
          proposals_raiz.each_with_index do |proposal, p_idx|
            es_ultima_proposal = p_idx == proposals_raiz.size - 1
            titulo_proposal = titulo.call(proposal)
            puts "#{sangria_proposals}#{es_ultima_proposal ? '   └─ ' : '   ├─ '}📄 #{titulo_proposal} (ID: #{proposal.id})"
            
            print_proposals_hijas(proposal.id, proposals_del_componente, proposals_por_id, titulo, 
                                 sangria_proposals, es_ultima_proposal ? "   " : "│  ")
          end
        end
      end
    end
  }

  # Función recursiva para imprimir el árbol
  print_nodo = ->(nodo, nivel, es_ultimo, sangria_acum = "") {
    prefijo = nivel == 0 ? (es_ultimo ? "└─ " : "├─ ") : (es_ultimo ? "└─ " : "├─ ")

    titulo_nodo = titulo.call(nodo)
    puts "#{sangria_acum}#{prefijo}🏛️  #{titulo_nodo} (ID: #{nodo.id})"

    sangria_hijos = "#{sangria_acum}#{es_ultimo ? '   ' : '│  '}"

    if comps_assembly[nodo.id]&.any?
      print_componentes.call(comps_assembly[nodo.id], sangria_hijos, "   ")
    end

    if procesos_por_asamblea[nodo.id]&.any?
      procesos_por_asamblea[nodo.id].each_with_index do |proceso, idx|
        es_ultimo_proceso = idx == procesos_por_asamblea[nodo.id].size - 1
        sangria_proceso = "#{sangria_hijos}#{es_ultimo_proceso ? '   ' : '│  '}"

        titulo_proceso = titulo.call(proceso)
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

  # Empezar por asambleas madre raiz
  asambleas_raiz = asambleas.select { |a| a.parent_id.nil? }

  if asambleas_raiz.any?
    asambleas_raiz.each_with_index do |raiz, idx|
      print_nodo.call(raiz, 0, idx == asambleas_raiz.size - 1)
    end
  else
    puts "   ⚠️  No hay círculos en esta organización"
  end

  # Conflictos sin asamblea
  procesos_sin_asamblea = procesos_por_asamblea[nil]

  if procesos_sin_asamblea&.any?
    puts "\n   📋 CONFLICTOS SIN CÍRCULO ASIGNADO:"
    procesos_sin_asamblea.each_with_index do |proceso, idx|
      es_ultimo = idx == procesos_sin_asamblea.size - 1
      prefijo = es_ultimo ? "   └─ " : "   ├─ "
      sangria_proceso = es_ultimo ? "      " : "   │  "

      titulo_proceso = titulo.call(proceso)
      puts "#{prefijo}🔥 #{titulo_proceso} (ID: #{proceso.id})"

      if comps_process[proceso.id]&.any?
        print_componentes.call(comps_process[proceso.id], sangria_proceso, "   ")
      end
    end
  end

  puts "\n" + ("─" * 120)

  # Estadísticas usando .size en arrays en lugar de .count en queries
  total_asambleas = asambleas.size
  total_procesos = procesos.size
  total_componentes = comps_assembly.values.flatten.size + comps_process.values.flatten.size
  total_proposals = todas_proposals.size

  # Calcular proposals con hijas de manera segura
  proposals_con_hijas = 0
  if todas_proposals.any?
    proposals_con_hijas = todas_proposals.count { |p| todas_proposals.any? { |h| h.parent_objective_id == p.id } }
  end

  # Calcular procesos con/sin asamblea
  procesos_con_asamblea = procesos.count { |p| p.parent_assembly_id.present? }
  procesos_sin_asamblea_count = procesos.count { |p| p.parent_assembly_id.nil? }

  puts "📊 ESTADÍSTICAS:"
  puts "   🏛️  Circulos: #{total_asambleas}"
  puts "   🔥  Conflictos: #{total_procesos}"
  puts "       ├─ Con Círculo: #{procesos_con_asamblea}"
  puts "       └─ Sin Círculo: #{procesos_sin_asamblea_count}"
  puts "   🔧 Componentes: #{total_componentes}"
  puts "   📄 Propuestas: #{total_proposals}"

  if total_proposals.positive?
    proposals_raiz = todas_proposals.count { |p| p.parent_objective_id.nil? }
    proposals_con_madre = todas_proposals.count { |p| p.parent_objective_id.present? }

    puts "      ├─ Raíces (sin madre): #{proposals_raiz}"
    puts "      ├─ Con madre: #{proposals_con_madre}"
    puts "      └─ Con hijas: #{proposals_con_hijas}"
  end
end

def print_proposals_hijas(madre_id, todas_proposals_del_componente, proposals_por_id,
                          titulo, sangria_base, prefijo_extra)
  # Método recursivo para imprimir proposals hijas
  hijas = todas_proposals_del_componente.select { |p| p.parent_objective_id == madre_id }

  hijas.each_with_index do |hija, idx|
    es_ultima_hija = idx == hijas.size - 1
    titulo_hija = titulo.call(hija)
    puts "#{sangria_base}#{prefijo_extra}#{es_ultima_hija ? '   └─ ' : '   ├─ '}📄 #{titulo_hija} (ID: #{hija.id})"

    print_proposals_hijas(hija.id, todas_proposals_del_componente, proposals_por_id, titulo, 
                        "#{sangria_base}#{prefijo_extra}", 
                        es_ultima_hija ? "   " : "│  ")
  end
end

arbol_final
def fsmac_arbol (org_id = 2, locale = 'es')
  # Obtener organización
  org = Decidim::Organization.find(org_id)
  nombre_org = org.name[locale] || org.name['es'] || org.name['en'] || "Organización #{org_id}"
  
  puts "\n"  + "═" * 80 
  puts "#{nombre_org} (ID: #{org_id})"

  puts "═" * 80
  
  # Obtener todas las asambleas de la organización
  asambleas = Decidim::Assembly
              .where(decidim_organization_id: org_id)
              .includes(:parent)
              .order(:parent_id, :id)
  
  # Obtener todos los procesos (conflictos) con sus asambleas asociadas
  procesos = Decidim::ParticipatoryProcess
             .where(decidim_organization_id: org_id)
             .includes(:assembly)
             .group_by(&:parent_assembly_id)
  
  # Función para obtener título en el locale especificado
  titulo = ->(objeto, defecto = "SIN TÍTULO") {
    return defecto unless objeto&.respond_to?(:title)
    objeto.title[locale] || objeto.title['es'] || objeto.title['en'] || defecto
  }
  
  # Encontrar asambleas raíz (sin padre)
  asambleas_raiz = asambleas.select { |a| a.parent_id.nil? }
  
  if asambleas_raiz.any?
    asambleas_raiz.each do |raiz|
      procesar_nodo_asamblea(raiz, asambleas, procesos, titulo, 1)
    end
  else
    puts "   ⚠️  No hay asambleas/círculos en esta organización"
  end
  
  # Procesos sin asamblea
  if procesos[nil]&.any?
    puts "\n   📋 CONFLICTOS SIN CÍRCULO ASIGNADO:"
    procesos[nil].each do |proceso|
      nombre_proceso = titulo.call(proceso, "Proceso #{proceso.id}")
      puts "   │  🔥 #{nombre_proceso} (ID: #{proceso.id})"
    end
  end
  
  puts "\n" + "=" * 80
  puts "Total: #{asambleas.count} asambleas, #{procesos.values.flatten.count} procesos"
end

def procesar_nodo_asamblea(asamblea, todas_asambleas, procesos, titulo, nivel)
  # Sangría según nivel
  sangria = "   " * nivel
  prefijo = nivel == 1 ? "├─ " : "│  " + "   " * (nivel-2) + "└─ "
  
  nombre_asamblea = titulo.call(asamblea, "Asamblea #{asamblea.id}")
  puts "#{sangria}#{prefijo}🏛️  #{nombre_asamblea} (ID: #{asamblea.id})"
  
  # Mostrar procesos de esta asamblea
  if procesos[asamblea.id]&.any?
    procesos[asamblea.id].each do |proceso|
      nombre_proceso = titulo.call(proceso, "Proceso #{proceso.id}")
      puts "#{sangria}   │  🔥 #{nombre_proceso} (ID: #{proceso.id})"
    end
  end
  
  # Buscar asambleas hijas
  hijas = todas_asambleas.select { |a| a.parent_id == asamblea.id }
  
  hijas.each_with_index do |hija, index|
    procesar_nodo_asamblea(hija, todas_asambleas, procesos, titulo, nivel + 1)
  end
end

fsmac_arbol

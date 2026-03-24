# Obtiene datos para aplicar a user_apply_roles.rb

def mostrar_organizacion(org_id)
  # Obtener organización completa
  org = Decidim::Organization.find(org_id)
  idiomas = org.available_locales

  puts "\n" + ("═" * 82)
  puts "DETALLE DE ORGANIZACIÓN"
  puts "═" * 82

  # Información básica
  puts "INFORMACIÓN GENERAL:"
  puts "  ID: #{org.id}"
  puts "  Host: #{org.host}"
  puts "  Tipo: #{org.class.name}"

  # Nombres en todos los idiomas
  puts "\n NOMBRES POR IDIOMA:"
  puts "  " + ("-" * 60)

  # Obtener nombres
  nombres = org.attributes["name"] || {}

  idiomas.each do |locale|
    nombre = nombres[locale]
    if nombre
      puts "  #{locale.upcase}: #{nombre}"
    else
      puts "  #{locale.upcase}:  No disponible"
    end
  end

  # Estadísticas de la organización
  circulos = Decidim::Assembly.where(decidim_organization_id: org).count
  conflictos = Decidim::ParticipatoryProcess.where(decidim_organization_id: org).count

  puts "\n ESTADÍSTICAS:"
  puts "  Usuarios: #{org.users.count}"
  puts "  Círculos: #{circulos}"
  puts "  Conflictos: #{conflictos}"

  # Configuración de idiomas
  puts "\n CONFIGURACIÓN DE IDIOMAS:"
  puts "  Idiomas disponibles: #{idiomas.join(', ')}"
  puts "  Idioma por defecto: #{org.default_locale}"
end

def listar_circulos(org_id)
  # Pacto social y asambleas dependientes
  org = Decidim::Organization.find(org_id)
  idiomas = org.available_locales

  # Consulta base de datos
  asambleas = Decidim::Assembly
              .where(decidim_organization_id: org_id)
              .joins("LEFT JOIN decidim_assemblies AS parents ON parents.id = decidim_assemblies.parent_id")
              .pluck(
                "decidim_assemblies.id",
                "decidim_assemblies.title",
                "decidim_assemblies.parent_id",
                "parents.title AS parent_title"
              )

  # Iterar sobre cada idioma
  idiomas.each do |locale|
    puts "\n" + ("=" * 100)
    puts "IDIOMA: #{locale.upcase}"
    puts "=" * 100

    # Cabeceras para este idioma
    puts sprintf("%-5s | %-40s | %-8s | %-40s\n", "ID", "CÍRCULO", "MADRE ID", "ASAMBLEA MADRE")
    puts "-" * 100

    # Procesar cada asamblea
    asambleas.each do |id, title_json, madre_id, madre_title_json|
      titulo = title_json[locale] if title_json
      titulo = titulo ? titulo.truncate(38) : "—"

      if madre_id
        madre_titulo = madre_title_json[locale] if madre_title_json
        madre_titulo = madre_titulo ? madre_titulo.truncate(38) : "—"
        printf "%-5d | %-40s | %-8d | %-40s\n", id, titulo, madre_id, madre_titulo
      end
    end
    puts "-" * 100
  end
end

def listar_conflictos(org_id)
  # Obtener la organización y sus idiomas disponibles
  org = Decidim::Organization.find(org_id)
  idiomas = org.available_locales

  puts "\n" + ("═" * 120)
  puts "CONFLICTOS Y CÍRCULOS".ljust(110)
  puts "Organización: #{org.name['es']} (ID: #{org_id})"
  puts "Idiomas disponibles: #{idiomas.join(', ')}"
  puts "═" * 120

  # Consulta con LEFT JOIN para incluir procesos sin círculo
  conflictos = Decidim::ParticipatoryProcess
               .left_joins(:assembly)
               .where(decidim_organization_id: org_id)
               .select(
                 "decidim_participatory_processes.id",
                 "decidim_participatory_processes.title",
                 "decidim_assemblies.id AS assembly_id",
                 "decidim_assemblies.title AS assembly_title"
               )
               .order("decidim_participatory_processes.id")

  # Función auxiliar para extraer título de JSON
  extract_title = ->(json, locale) {
    return "—" unless json

    json[locale] ? json[locale].truncate(40) : "—"
  }

  # Contador
  total = 0

  # Mostrar cada conflicto con todos los idiomas
  conflictos.each do |c|
    total += 1
    tiene_circulo = c.assembly_id.present?

    puts "\n" + ("─" * 120)
    puts " CONFLICTO ID: #{c.id}"

    # Títulos del conflicto en todos los idiomas
    idiomas.each do |locale|
      titulo = extract_title.call(c.title, locale)
      puts "    #{locale.upcase}: #{titulo}"
    end

    # Información del círculo (asamblea)
    if tiene_circulo
      puts "  CÍRCULO ASOCIADO ID: #{c.assembly_id})"

      idiomas.each do |locale|
        titulo_circulo = extract_title.call(c.assembly_title, locale)
        puts "   #{locale.upcase}: #{titulo_circulo}"
      end
    else
      puts "   SIN CÍRCULO ASOCIADO"
    end

    puts "─" * 120
  end
end

#### MAIN ####

organizacion_id = 2

# Mostrar organización
mostrar_organizacion(organizacion_id)

# Mostrar Circulos
listar_circulos(organizacion_id)

# Mostrar conflictos
listar_conflictos(organizacion_id)

# generar_traducciones.rb
# Script para generar YAML de traducciones (Asamblea -> Círculo)
# Ejecutar con: rails runner generar_traducciones.rb

# Ejecución:

# Ver estadísticas de cuántas traducciones hay
# rails runner generar_traducciones.rb --stats

# Ver árbol de traducciones
# rails runner generar_traducciones.rb --tree

# Generar archivo completo (incluye admin)
# rails runner generar_traducciones.rb mis_traducciones.yml

# Usar nombre por defecto (traducciones_completas.yml)
# rails runner generar_traducciones.rb

def generate_ready_to_use_yaml(
  terms = [/asamblea/i,
    /asambleas/i,
    /la asamblea/i,
    /esta asamblea/i,
    /estas asambleas/i,
    /las asambleas/i,
    /de la asamblea/i,
    /proceso/i,
    /procesos/i,
    /proceso participativo/i,
    /procesos participativos/i],
  replacements = {
    # Términos compuestos (ordenados de más específico a más general)
    /la asamblea/i => "el círculo",
    /las asambleas/i => "los círculos",
    /de la asamblea/i => "del círculo",
    /esta asamblea/i => "este circulo",
    /estas asambleas/i => "estos circulos",
    /de las asambleas/i => "de los círculos",
    /a la asamblea/i => "al círculo",
    /a las asambleas/i => "a los círculos",
    /en la asamblea/i => "en el círculo",
    /en las asambleas/i => "en los círculos",
    
    # Términos individuales con mayúsculas/minúsculas
    /asamblea/i => "círculo",
    /Asamblea/ => "Círculo",
    /ASAMBLEA/ => "CÍRCULO",
    /asambleas/i => "círculos",
    /Asambleas/ => "Círculos",
    /ASAMBLEAS/ => "CÍRCULOS",
    
    # Términos de proceso -> conflicto
    /proceso/i => "conflicto",
    /Proceso/ => "Conflicto",
    /PROCESO/ => "CONFLICTO",
    /procesos/i => "conflictos",
    /Procesos/ => "Conflictos",
    /PROCESOS/ => "CONFLICTOS",
    /proceso participativo/i => "conflicto",
    /procesos participativos/i => "conflictos"
  },
  exclude_patterns = [],  # Vacío para incluir admin
  output_file = "traducciones_completas.yml"
)
  
  puts "🔍 Buscando traducciones que contengan términos a reemplazar..."
  puts "   📝 Incluyendo admin (sin exclusiones)"
  puts "   🔄 Reemplazos: asamblea→círculo, proceso→conflicto"
  
  # Asegurar locale español
  I18n.locale = :es
  #I18n.t("decidim").keys
  all_translations = I18n.backend.translations[:es]

  if all_translations.nil?
    puts "❌ Error: No se encontraron traducciones en español"
    return
  end
  
  results = {}
  
  # Función para reemplazar texto respetando mayúsculas/minúsculas
  def smart_replace(text, replacements)
    modified = text.dup
    
    # Ordenar reemplazos por longitud descendente para evitar reemplazos parciales
    sorted_replacements = replacements.sort_by { |k, _| -k.to_s.length }
    
    sorted_replacements.each do |pattern, replacement|
      modified.gsub!(pattern, replacement)
    end
    
    modified
  end
  
  # Función para determinar el tipo de comillas a usar
  def quote_value(value)
    if value.include?("'") && !value.include?('"')
      "\"#{value}\""
    elsif value.include?('"') && !value.include?("'")
      "'#{value}'"
    elsif value.include?("'") && value.include?('"')
      "\"#{value.gsub('"', '\\"')}\""
    elsif value.match?(/[:\{\}\[\],&*#?|\-<>=!%@`]/)
      "'#{value}'"
    else
      value
    end
  end
  
  # Búsqueda recursiva
  search_recursive = lambda do |hash, current_path|
    hash.each do |key, value|
      new_path = current_path.empty? ? key.to_s : "#{current_path}.#{key}"
      
      # Saltar SOLO si hay exclusiones (ahora está vacío)
      next if exclude_patterns.any? { |p| new_path.match?(p) }
      
      if value.is_a?(Hash)
        search_recursive.call(value, new_path)
      elsif value.is_a?(String)
        terms.each do |term|
          if value.match?(term)
            parts = new_path.split('.')
            current = results
            parts.each_with_index do |part, index|
              if index == parts.length - 1
                current[part] = smart_replace(value, replacements)
              else
                current[part] ||= {}
                current = current[part]
              end
            end
            break
          end
        end
      end
    end
  end
  
  search_recursive.call(all_translations, "")
  
  # Función para ordenar hash alfabéticamente
  def sort_hash(obj)
    return obj unless obj.is_a?(Hash)
    sorted = {}
    obj.keys.sort.each do |key|
      sorted[key] = sort_hash(obj[key])
    end
    sorted
  end
  
  # Función para generar YAML con indentación y comillas inteligentes
  def hash_to_yaml(hash, indent = 0)
    output = []
    hash.each do |key, value|
      if value.is_a?(Hash)
        output << "#{'  ' * indent}#{key}:"
        output << hash_to_yaml(value, indent + 1)
      else
        quoted_value = quote_value(value)
        output << "#{'  ' * indent}#{key}: #{quoted_value}"
      end
    end
    output.flatten.join("\n")
  end
  
  # Contar claves
  def count_keys(hash)
    count = 0
    hash.each do |_, value|
      if value.is_a?(Hash)
        count += count_keys(value)
      else
        count += 1
      end
    end
    count
  end
  
  sorted_results = sort_hash(results)
  
  # Generar YAML
  yaml_output = "# Archivo generado automáticamente el #{Time.now.strftime('%Y-%m-%d %H:%M')}\n"
  yaml_output << "# INCLUYE ADMIN - Reemplaza: asamblea→círculo, proceso→conflicto\n"
  yaml_output << "# Ejecutado con: rails runner #{File.basename(__FILE__)}\n\n"
  yaml_output << "es:\n"
  yaml_output << hash_to_yaml(sorted_results, 1)
  
  # Guardar archivo
  File.write(output_file, yaml_output)
  
  # Mostrar resultados
  total_keys = count_keys(sorted_results)
  puts "\n" + "=" * 70
  puts "✅ PROCESO COMPLETADO"
  puts "=" * 70
  puts "📊 Total traducciones encontradas: #{total_keys}"
  puts "📁 Archivo generado: #{File.expand_path(output_file)}"
  puts "📦 Tamaño: #{File.size(output_file)} bytes"
  
  # Mostrar estadísticas por módulo
  puts "\n📊 DISTRIBUCIÓN POR MÓDULO:"
  modules = {}
  sorted_results.each do |key, _|
    modules[key.to_s] = count_keys(sorted_results[key])
  end
  modules.sort_by { |_, v| -v }.each do |mod, count|
    puts "   📁 #{mod}: #{count} traducciones"
  end
  
  # Mostrar vista previa
  puts "\n🔍 VISTA PREVIA (primeras 15 líneas):"
  puts "-" * 50
  system("head -n 15 #{output_file}") if File.exist?(output_file)
  
  puts "\n📋 Para usar este archivo:"
  puts "   1. Revisa el contenido de #{output_file}"
  puts "   2. Si todo está correcto:"
  puts "      cp #{output_file} config/locales/overrides.es.yml"
  puts "   3. Reinicia la aplicación"
  
  sorted_results
end

# También podemos crear una versión para ver el árbol
def mostrar_arbol_traducciones
  puts "\n" + "=" * 70
  puts "🌳 ÁRBOL DE TRADUCCIONES (incluyendo admin)"
  puts "=" * 70
  
  def print_hash(hash, indent = 0, max_depth = 3)
    hash.each do |key, value|
      if value.is_a?(Hash) && indent < max_depth
        puts "#{'  ' * indent}📁 #{key}:"
        print_hash(value, indent + 1, max_depth)
      elsif !value.is_a?(Hash)
        puts "#{'  ' * indent}📄 #{key}: \"#{value}\""
      end
    end
  end
  
  all_translations = I18n.t("decidim") rescue {}
  print_hash(all_translations, 0, 2)  # Profundidad 2 para no saturar
end

# Asegurar locale español
I18n.locale = :es
I18n.t("decidim").keys

# Ejecutar según argumentos
if ARGV.include?("--tree")
  mostrar_arbol_traducciones
elsif ARGV.include?("--stats")
  # Mostrar estadísticas sin generar archivo
  puts "🔍 Analizando términos a reemplazar..."
  I18n.locale = :es
  all_translations = I18n.backend.translations[:es]
  
  def count_term_occurrences(hash, term, path = "")
    count = 0
    hash.each do |key, value|
      current_path = path.empty? ? key.to_s : "#{path}.#{key}"
      if value.is_a?(Hash)
        count += count_term_occurrences(value, term, current_path)
      elsif value.is_a?(String) && value.match?(term)
        count += 1
        puts "   #{current_path}: #{value[0..50]}..." if value.length > 50
      end
    end
    count
  end
  
  ["asamblea", "proceso"].each do |term|
    count = count_term_occurrences(all_translations, /#{term}/i)
    puts "📊 '#{term}': #{count} ocurrencias"
  end
else
  # Parámetros personalizables
  output_file = ARGV[0] || "traducciones_completas.yml"
  
  # Ejecutar generación principal
  generate_ready_to_use_yaml(
    [/asamblea/i, /asambleas/i, /la asamblea/i, /las asambleas/i, /de la asamblea/i, /proceso/i, /procesos/i],
    {
      # Términos compuestos con asamblea
      /la asamblea/i => "el círculo",
      /las asambleas/i => "los círculos",
      /de la asamblea/i => "del círculo",
      /de las asambleas/i => "de los círculos",

      # Términos individuales asamblea
      /asamblea/i => "círculo",
      /Asamblea/ => "Círculo",
      /ASAMBLEA/ => "CÍRCULO",
      /asambleas/i => "círculos",
      /Asambleas/ => "Círculos",
      /ASAMBLEAS/ => "CÍRCULOS",
      
      # Términos individuales proceso
      /proceso/i => "conflicto",
      /Proceso/ => "Conflicto",
      /PROCESO/ => "CONFLICTO",
      /procesos/i => "conflictos",
      /Procesos/ => "Conflictos",
      /PROCESOS/ => "CONFLICTOS"
    },
    [],  # Sin exclusiones
    output_file
  )
end
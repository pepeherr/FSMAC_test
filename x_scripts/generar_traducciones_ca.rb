# x_scripts/generar_traducciones_ca.rb
# Ejecutar: rails runner generar_traducciones_ca.rb

def generate_filtered_yaml(output_file = "traducciones_ca.yml")
  puts "=" * 70
  puts "🔍 GENERANDO TRADUCCIONES FILTRADAS (TODOS LOS NAMESPACES)"
  puts "=" * 70
  
  # Forzar carga de traducciones
  I18n.locale = :ca
  
  # Cargar diferentes namespaces para forzar su inicialización
  puts "⏳ Cargando todos los namespaces de traducciones..."
  [
    "decidim",
    "activemodel",
    "activerecord",
    "layouts",
    "devise",
    "forms",
    "errors",
    "date",
    "time",
    "number",
    "support"
  ].each do |namespace|
    begin
      I18n.t(namespace).keys
      print "."
    rescue
      print "x"
    end
  end
  puts "\n✅ Namespaces cargados"
  
  # Obtener TODAS las traducciones
  all_translations = I18n.backend.translations[:ca]
  
  if all_translations.nil?
    puts "❌ Error: No se encontraron traducciones en catalán"
    return
  end
  
  puts "✅ Traducciones españolas encontradas"
  puts "📊 Namespaces principales: #{all_translations.keys.inspect}"
  
  # Definir patrones de búsqueda
  search_patterns = [
    /assemblea/i,
    /l'assemblea/i,
    /les assemblees/i,
    /procés/i,
    /processos/i
  ]
  
  # Definir reemplazos (ordenados de más específico a más general)
  replacements = {
    # Términos compuestos con asamblea
    /assemblea/i => "cercle",
    /l'assemblea/i => "el cercle",
    /de l'assemblea/i => "del cercle",
    /de las assemblees/i => "dels cercles",
    /a les assemblees/ => 'als  cercles',
    /a l'assemblea/i => 'al cercle',
    
    # Términos individuales asamblea
    /\bassemblea\b/i => "cercle",
    /\bAsseblea\b/ => "Cercle",
    /\bASSEMBLEA\b/ => "CERCLE",
    /\bassemblees\b/i => "cercles",
    /\bAssemblees\b/ => "Cercles",
    /\bASSEMBLEES\b/ => "CERCLES",
    
    # Términos individuales proceso
    /\bprocés\b/i => "conflicte",
    /\bProcés\b/ => "Conflicte",
    /\bPROCÉS\b/ => "CONFLICTE",
    /\bprocessos\b/i => "conflictes",
    /\bProcessos\b/ => "Conflictes",
    /\bPROCESSOS\b/ => "CONFLICTES"
  }
  
  # Función para verificar si un valor contiene algún patrón
  def matches_any_pattern?(value, patterns)
    return false unless value.is_a?(String)
    patterns.any? { |p| value.match?(p) }
  end
  
  # Función para aplicar reemplazos
  def apply_replacements(text, replacements)
    return text unless text.is_a?(String)
    modified = text.dup
    replacements.each do |pattern, replacement|
      modified.gsub!(pattern, replacement)
    end
    modified
  end
  
  # Función para filtrar y transformar recursivamente
  def filter_and_transform(obj, patterns, replacements, path = [])
    case obj
    when Hash
      result = {}
      obj.each do |key, value|
        new_path = path + [key]
        transformed = filter_and_transform(value, patterns, replacements, new_path)
        # Solo incluir si hay resultados
        if !transformed.nil? && !(transformed.is_a?(Hash) && transformed.empty?)
          result[key] = transformed
        end
      end
      result.empty? ? nil : result
      
    when Array
      result = []
      obj.each_with_index do |item, idx|
        new_path = path + ["[#{idx}]"]
        transformed = filter_and_transform(item, patterns, replacements, new_path)
        result << transformed unless transformed.nil?
      end
      result.empty? ? nil : result
      
    when String
      if matches_any_pattern?(obj, patterns)
        apply_replacements(obj, replacements)
      else
        nil
      end
      
    else
      nil
    end
  end
  
  # Función para generar YAML limpio
  def hash_to_clean_yaml(hash, indent = 0)
    return "" if hash.nil? || (hash.is_a?(Hash) && hash.empty?)
    
    output = []
    hash.each do |key, value|
      if value.is_a?(Hash)
        nested = hash_to_clean_yaml(value, indent + 1)
        if nested.present?
          output << "#{'  ' * indent}#{key}:"
          output << nested
        end
      elsif value.is_a?(Array)
        array_output = []
        value.each do |item|
          if item.is_a?(Hash)
            item_output = hash_to_clean_yaml(item, indent + 2)
            array_output << "#{'  ' * (indent + 1)}-"
            array_output << item_output.lines.map { |l| "  #{l}" }.join if item_output.present?
          else
            array_output << "#{'  ' * (indent + 1)}- #{quote_value(item.to_s)}"
          end
        end
        if array_output.any?
          output << "#{'  ' * indent}#{key}:"
          output << array_output
        end
      else
        output << "#{'  ' * indent}#{key}: #{quote_value(value.to_s)}"
      end
    end
    output.flatten.join("\n")
  end
  
  def quote_value(str)
    if str.include?("'") && !str.include?('"')
      "\"#{str}\""
    elsif str.include?('"') && !str.include?("'")
      "'#{str}'"
    elsif str.include?("'") && str.include?('"')
      "\"#{str.gsub('"', '\\"')}\""
    elsif str.match?(/[:\{\}\[\],&*#?|\-<>=!%@`]/)
      "'#{str}'"
    else
      str
    end
  end
  
  # Función para contar elementos
  def count_elements(obj)
    case obj
    when Hash
      obj.values.sum { |v| count_elements(v) }
    when Array
      obj.sum { |v| count_elements(v) }
    when String, Symbol, Numeric, TrueClass, FalseClass
      1
    else
      0
    end
  end
  
  puts "⏳ Filtrando y transformando traducciones en TODOS los namespaces..."
  
  # Aplicar filtrado y transformación a TODAS las traducciones
  filtered = filter_and_transform(all_translations, search_patterns, replacements)
  
  if filtered.nil? || filtered.empty?
    puts "❌ No se encontraron traducciones con los patrones especificados"
    return
  end
  
  # Generar YAML
  yaml_output = "# Archivo generado automáticamente el #{Time.now.strftime('%Y-%m-%d %H:%M')}\n"
  yaml_output << "# SOLO claves que contienen: asamblea, proceso (y variantes)\n"
  yaml_output << "# Incluye TODOS los namespaces (decidim, activemodel, activerecord, layouts, etc.)\n"
  yaml_output << "# Reemplazos aplicados: asamblea→círculo, proceso→conflicto\n\n"
  yaml_output << "es:\n"
  yaml_output << hash_to_clean_yaml(filtered, 1)
  
  File.write(output_file, yaml_output)
  
  total = count_elements(filtered)
  puts "\n" + "=" * 70
  puts "✅ PROCESO COMPLETADO"
  puts "=" * 70
  puts "📊 Total traducciones encontradas y transformadas: #{total}"
  puts "📁 Archivo: #{File.expand_path(output_file)}"
  puts "📦 Tamaño: #{File.size(output_file)} bytes"
  
  # Mostrar estadísticas por namespace
  puts "\n📊 DISTRIBUCIÓN POR NAMESPACE:"
  filtered.keys.sort.each do |namespace|
    count = count_elements(filtered[namespace])
    puts "   📁 #{namespace}: #{count} traducciones" if count > 0
  end
  
  # Mostrar ejemplos de activemodel si existen
  if filtered[:activemodel]
    puts "\n🔍 EJEMPLOS DE ACTIVEMODEL:"
    examples = 0
    find_examples = lambda do |h, path|
      h.each do |k, v|
        current = path.empty? ? k.to_s : "#{path}.#{k}"
        if v.is_a?(Hash)
          find_examples.call(v, current)
        elsif v.is_a?(String)
          puts "   📌 activemodel.#{current}: \"#{v}\""
          examples += 1
        end
        break if examples >= 5
      end
    end
    find_examples.call(filtered[:activemodel], "")
  end
  
  # Mostrar ejemplos de decidim
  if filtered[:decidim]
    puts "\n🔍 EJEMPLOS DE DECIDIM:"
    examples = 0
    find_examples = lambda do |h, path|
      h.each do |k, v|
        current = path.empty? ? k.to_s : "#{path}.#{k}"
        if v.is_a?(Hash)
          find_examples.call(v, current)
        elsif v.is_a?(String)
          puts "   📌 decidim.#{current}: \"#{v}\""
          examples += 1
        end
        break if examples >= 5
      end
    end
    find_examples.call(filtered[:decidim], "")
  end
  
  puts "\n📋 INSTRUCCIONES:"
  puts "   1. Revisa el archivo: less #{output_file}"
  puts "   2. Si todo está correcto:"
  puts "      cp #{output_file} config/locales/overrides.es.yml"
  puts "   3. Reinicia la aplicación"
  puts "   4. Verifica los cambios en la web (incluyendo formularios y layouts)"
  
  filtered
end

# Ejecutar
generate_filtered_yaml(ARGV[0] || "traducciones_filtradas_completo.yml")
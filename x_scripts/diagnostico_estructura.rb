# diagnosticar_estructura.rb
# Ejecutar: rails runner diagnosticar_estructura.rb

puts "=" * 70
puts "🔍 DIAGNÓSTICO DE ESTRUCTURA DE TRADUCCIONES"
puts "=" * 70

I18n.locale = :es
I18n.t("decidim").keys
all_translations = I18n.backend.translations[:es]

if all_translations.nil?
  puts "❌ No hay traducciones en español"
  exit
end

puts "✅ Traducciones españolas cargadas"
puts "📊 Total claves primer nivel: #{all_translations.keys.size}"
puts "📊 Claves primer nivel: #{all_translations.keys.inspect}"

# Ver si existe decidim
if all_translations.key?(:decidim)
  puts "\n✅ Módulo :decidim ENCONTRADO"
  puts "📊 Subclaves de decidim: #{all_translations[:decidim].keys.inspect}"
  
  # Ver algunas traducciones de ejemplo
  puts "\n📝 EJEMPLOS DE TRADUCCIONES:"
  sample_keys = [:menu, :assemblies, :admin].select { |k| all_translations[:decidim].key?(k) }
  sample_keys.each do |key|
    if all_translations[:decidim][key].is_a?(Hash)
      puts "  decidim.#{key}: #{all_translations[:decidim][key].keys.first(3)}"
    else
      puts "  decidim.#{key}: #{all_translations[:decidim][key]}"
    end
  end
else
  puts "\n❌ Módulo :decidim NO ENCONTRADO"
  puts "Buscando rutas alternativas..."
  
  # Buscar recursivamente cualquier traducción que contenga "asamblea"
  def find_assembly_translations(hash, path = [])
    results = []
    hash.each do |key, value|
      current_path = path + [key]
      if value.is_a?(Hash)
        results += find_assembly_translations(value, current_path)
      elsif value.is_a?(String) && value.match?(/asamblea/i)
        results << { path: current_path.join('.'), value: value }
      end
    end
    results
  end
  
  assembly_translations = find_assembly_translations(all_translations)
  
  if assembly_translations.any?
    puts "\n✅ Encontradas #{assembly_translations.size} traducciones con 'asamblea':"
    assembly_translations.first(10).each do |t|
      puts "  📌 #{t[:path]}: \"#{t[:value][0..50]}...\""
    end
  else
    puts "❌ No se encontraron traducciones con 'asamblea'"
  end
end

# Ver estructura completa (primeros 2 niveles)
puts "\n" + "=" * 70
puts "🌳 ESTRUCTURA PRIMEROS 2 NIVELES:"
puts "=" * 70

def print_structure(hash, level = 0, max_level = 2)
  return unless hash.is_a?(Hash)
  
  hash.each do |key, value|
    puts "#{'  ' * level}📁 #{key}"
    if level < max_level && value.is_a?(Hash)
      print_structure(value, level + 1, max_level)
    end
  end
end

print_structure(all_translations, 0, 1)
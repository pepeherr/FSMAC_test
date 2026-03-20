# x_scripts/decidim_ver_asociaciones.rb
# rails runner scripts/ver_asociaciones.rb

def mostrar_asociaciones(modelo, nombre_modelo)
  puts "\n" + "=" * 80
  puts "ASOCIACIONES DEL MODELO: #{nombre_modelo}"
  puts "=" * 80

  # Obtener todas las asociaciones
  asociaciones = modelo.reflect_on_all_associations

  if asociaciones.empty?
    puts "No se encontraron asociaciones"
    return
  end

  # Agrupar por tipo
  por_tipo = asociaciones.group_by(&:macro)

  por_tipo.each do |tipo, lista|
    puts "\n📌 #{tipo.to_s.upcase} (#{lista.size})"
    puts "-" * 40

    lista.each do |assoc|
      puts "  • #{assoc.name}"
      puts "    Clase: #{assoc.class_name}"
      puts "    FK: #{assoc.foreign_key}" if assoc.foreign_key
      puts "    Opciones: #{assoc.options.inspect[0..80]}..."
      puts
    end
  end
end

# Con diferentes modelos
mostrar_asociaciones(Decidim::Assembly, "Decidim::Assembly")
mostrar_asociaciones(Decidim::ParticipatoryProcess, "Decidim::ParticipatoryProcess")
mostrar_asociaciones(Decidim::Proposals::Proposal, "Decidim::Proposals::Proposal")
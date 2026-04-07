# scripts/test_menu.rb
puts "=" * 21
puts "VERIFICACIÓN DE MENÚS"
puts "=" * 21

menus_a_probar = Decidim::MenuRegistry.instance_values["all"].keys

menus_a_probar.each do |menu_name|
  menu_registry = Decidim::MenuRegistry.find(menu_name)
  puts "Menú: :#{menu_name}"
  puts "   Configuraciones: #{menu_registry.configurations.count}"
  # Cada menú es un objeto que contiene los items registrados
  if menu.respond_to?("configurations")
    menu.items.each do |item|
      puts "  - #{item.name}: #{item.url}"
      puts "    Active: #{item.active?}"
      puts "    Position: #{item.position}"
      puts "    Options: #{item.options}"
    end
  end
  puts "\n"
rescue StandardError
  puts " :#{menu_name} - NO ENCONTRADO O SIN CONFIGURACIONES"
end

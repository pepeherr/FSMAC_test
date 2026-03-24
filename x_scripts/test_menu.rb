# scripts/test_menu.rb
puts "=" * 60
puts "VERIFICACIÓN DE MENÚS"
puts "=" * 60

menus_a_probar = [:navbar, :user_menu, :menu, :main_menu, :admin_menu]

menus_a_probar.each do |menu_name|
  begin
    menu_registry = Decidim::MenuRegistry.find(menu_name)
    puts "✅ :#{menu_name} - ENCONTRADO"
    puts "   Configuraciones: #{menu_registry.configurations.count}"
  rescue
    puts "❌ :#{menu_name} - NO ENCONTRADO"
  end
end
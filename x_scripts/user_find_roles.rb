#!/usr/bin/env ruby
# Script para verificar roles de un usuario en espacios participativos

def ver_roles_usuario(usuario_id)
  begin
    usuario = Decidim::User.find(usuario_id)
    
    puts "\n USUARIO: #{usuario.name} (#{usuario.email})"
    puts "ID: #{usuario.id}"
    puts "=" * 60
    
    # 1. ROLES EN CIRCULOS
    puts "\n CIRCULOS (Decidim::Assembly):"
    puts "-" * 40
    
    roles_assembly = Decidim::AssemblyUserRole.where(decidim_user_id: usuario_id)
    
    if roles_assembly.any?
      roles_assembly.each do |role_record|
        assembly = Decidim::Assembly.find_by(id: role_record.decidim_assembly_id)
        nombre_assembly = assembly ? assembly.title['es'] || assembly.title['en'] || "ID: #{role_record.decidim_assembly_id}" : "Circulo no encontrado (ID: #{role_record.decidim_assembly_id})"
        
        puts "     #{nombre_assembly}"
        puts "     ID Circulo: #{role_record.decidim_assembly_id}"
        puts "     Rol: #{role_record.role}"
        puts "     Creado: #{role_record.created_at.strftime('%d/%m/%Y') if role_record.created_at}"
        puts
      end
    else
      puts "  No tiene roles en asambleas"
    end
    
    # 2. ROLES EN CONFLICTOS
    puts "\n CONFLICTOS (Decidim::ParticipatoryProcess):"
    puts "-" * 40
    
    roles_process = Decidim::ParticipatoryProcessUserRole.where(decidim_user_id: usuario_id)
    
    if roles_process.any?
      roles_process.each do |role_record|
        process = Decidim::ParticipatoryProcess.find_by(id: role_record.decidim_participatory_process_id)
        nombre_process = process ? process.title['es'] || process.title['en'] || "ID: #{role_record.decidim_participatory_process_id}" : "Conflicto no encontrado (ID: #{role_record.decidim_participatory_process_id})"
        
        puts "     #{nombre_process}"
        puts "     ID Conflicto: #{role_record.decidim_participatory_process_id}"
        puts "     Rol: #{role_record.role}"
        puts "     Creado: #{role_record.created_at.strftime('%d/%m/%Y') if role_record.created_at}"
        puts
      end

    else
      puts "  No tiene roles en procesos participativos"
    end
    
    # 3. RESUMEN
    puts "\n RESUMEN:"
    puts "-" * 40
    total_roles = roles_assembly.count + roles_process.count
    puts "  Total roles: #{total_roles}"
    puts "  En asambleas: #{roles_assembly.count}"
    puts "  En procesos: #{roles_process.count}"
    
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5) if e.backtrace
  end
end

# Ejecutar si se proporciona un ID como argumento
if ARGV[0]
  ver_roles_usuario(ARGV[0].to_i)
else
  puts "   Uso: rails runner x_scripts/user_find_roles.rb <usuario_id>"
  puts "   Ejemplo: rails runner x_script/user_find_roles.rb 124"
end
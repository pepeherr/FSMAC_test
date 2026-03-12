#!/usr/bin/env ruby
# Script para asignar roles con modo SANDBOX (prueba sin guardar)

def asignar_rol(usuario_id, espacio_id, tipo_espacio, rol, modo_sandbox: true)
  puts "\n INICIANDO ASIGNACIÓN DE ROL"
  puts "=" * 60
  puts "   PARÁMETROS:"
  puts "   Usuario ID: #{usuario_id}"
  puts "   Espacio ID: #{espacio_id}"
  puts "   Tipo: #{tipo_espacio}"
  puts "   Rol: #{rol}"
  puts "   Modo: #{modo_sandbox ? ' SANDBOX (solo simulación)' : ' PRODUCCIÓN (guardará en BD)'}"
  puts "=" * 60

  begin
    # 1. VALIDACIONES PREVIAS
    puts "\n Validando datos..."

    # Validar usuario
    usuario = Decidim::User.find_by(id: usuario_id)
    if usuario.nil?
      puts " Error: No existe usuario con ID: #{usuario_id}"
      return false
    end
    puts "    Usuario: #{usuario.name} (#{usuario.email})"

    # Validar rol
    roles_validos = ["admin", "collaborator", "moderator", "valuator"]
    unless roles_validos.include?(rol)
      puts " Error: Rol '#{rol}' no válido. Válidos: #{roles_validos.join(', ')}"
      return false
    end
    puts "    Rol válido: #{rol}"

    # 2. VALIDAR ESPACIO SEGÚN TIPO
    case tipo_espacio
    when "assembly"
      espacio = Decidim::Assembly.find_by(id: espacio_id)
      if espacio.nil?
        puts "  Error: No existe asamblea con ID: #{espacio_id}"
        return false
      end
      puts "    Asamblea: #{espacio.title['es'] || espacio.title['en']} (ID: #{espacio.id})"

      # Verificar si ya existe el rol
      existe = Decidim::AssemblyUserRole.exists?(
        decidim_user_id: usuario_id,
        decidim_assembly_id: espacio_id,
        role: rol
      )

    when "process"
      espacio = Decidim::ParticipatoryProcess.find_by(id: espacio_id)
      if espacio.nil?
        puts " Error: No existe proceso con ID: #{espacio_id}"
        return false
      end
      puts "    Proceso: #{espacio.title['es'] || espacio.title['en']} (ID: #{espacio.id})"

      # Verificar si ya existe el rol
      existe = Decidim::ParticipatoryProcessUserRole.exists?(
        decidim_user_id: usuario_id,
        decidim_participatory_process_id: espacio_id,
        role: rol
      )

    else
      puts "  Error: Tipo '#{tipo_espacio}' no válido. Usa 'assembly' o 'process'"
      return false
    end

    # 3. VERIFICAR SI YA TIENE EL ROL
    if existe
      puts "\n ADVERTENCIA: El usuario YA TIENE el rol '#{rol}' en este espacio"
      puts "   No se realizarán cambios."
      return false
    else
      puts "\n Validación superada: El usuario NO tiene este rol actualmente"
    end

    # 4. MOSTRAR RESUMEN DE LA OPERACIÓN
    puts "\n RESUMEN DE LA OPERACIÓN:"
    puts "   Se asignará rol: #{rol}"
    puts "   A usuario: #{usuario.name} (ID: #{usuario.id})"
    puts "   En #{tipo_espacio}: #{espacio.title['es'] || espacio.title['en']} (ID: #{espacio.id})"
    
    # 5. EJECUTAR O SIMULAR SEGÚN MODO
    if modo_sandbox
      puts "\n MODO SANDBOX: No se guardarán cambios en la base de datos"
      puts "\n SQL que se ejecutaría:"
      case tipo_espacio
      when "assembly"
        puts "   INSERT INTO decidim_assembly_user_roles"
        puts "   (decidim_user_id, decidim_assembly_id, role, created_at, updated_at)"
        puts "   VALUES (#{usuario_id}, #{espacio_id}, '#{rol}', NOW(), NOW());"
      when "process"
        puts "   INSERT INTO decidim_participatory_process_user_roles"
        puts "   (decidim_user_id, decidim_participatory_process_id, role, created_at, updated_at)"
        puts "   VALUES (#{usuario_id}, #{espacio_id}, '#{rol}', NOW(), NOW());"
      end
      
      puts "\n SIMULACIÓN COMPLETADA - No se guardó nada"
      return true
      
    else
      # MODO REAL - CON TRANSACCIÓN
      puts "\n MODO PRODUCCIÓN: Guardando cambios..."
      
      # Usar transacción para poder hacer rollback si algo falla
      ActiveRecord::Base.transaction do
        case tipo_espacio
        when "assembly"
          role = Decidim::AssemblyUserRole.create!(
            decidim_user_id: usuario_id,
            decidim_assembly_id: espacio_id,
            role: rol
          )
          puts "    Rol creado con ID: #{role.id}"
          
        when "process"
          role = Decidim::ParticipatoryProcessUserRole.create!(
            decidim_user_id: usuario_id,
            decidim_participatory_process_id: espacio_id,
            role: rol
          )
          puts "    Rol creado con ID: #{role.id}"
        end
        
        puts "\n CAMBIOS GUARDADOS CORRECTAMENTE"
        puts "   (Puedes hacer rollback si es necesario, pero ya están confirmados)"
      end
      
      return true
    end

  rescue => e
    puts "\n ERROR INESPERADO: #{e.message}"
    puts e.backtrace.first(3) if e.backtrace
    return false
  end
end

# Función para probar con diferentes escenarios
def probar_escenarios
  puts "\n  EJECUTANDO BATERÍA DE PRUEBAS"
  puts "=" * 60
  
  escenarios = [
    { id: 1, desc: "Usuario existente - Asamblea", usuario: 124, espacio: 1, tipo: "assembly", rol: "admin" },
    { id: 2, desc: "Usuario existente - Proceso", usuario: 7, espacio: 1, tipo: "process", rol: "moderator" },
    { id: 3, desc: "Usuario inexistente", usuario: 99999, espacio: 1, tipo: "assembly", rol: "admin" },
    { id: 4, desc: "Rol no válido", usuario: 124, espacio: 1, tipo: "assembly", rol: "superadmin" },
    { id: 5, desc: "Espacio inexistente", usuario: 124, espacio: 99999, tipo: "assembly", rol: "admin" }
  ]
  
  escenarios.each do |esc|
    puts "\n" + "-" * 40
    puts "ESCENARIO #{esc[:id]}: #{esc[:desc]}"
    puts "-" * 40
    
    asignar_rol(
      esc[:usuario], 
      esc[:espacio], 
      esc[:tipo], 
      esc[:rol], 
      modo_sandbox: true
    )
  end
end

# Función para modo interactivo
def modo_interactivo
  puts "\n🎮 MODO INTERACTIVO"
  puts "=" * 60
  
  print "ID de usuario: "
  usuario_id = gets.chomp.to_i
  
  print "ID del espacio: "
  espacio_id = gets.chomp.to_i
  
  print "Tipo (assembly/process): "
  tipo = gets.chomp.downcase
  
  print "Rol (admin/collaborator/moderator/valuator): "
  rol = gets.chomp.downcase
  
  print "¿Modo sandbox? (s/N): "
  sandbox = gets.chomp.downcase != 'n'
  
  asignar_rol(usuario_id, espacio_id, tipo, rol, modo_sandbox: sandbox)
end

# MENÚ PRINCIPAL
if ARGV.length >= 1
  case ARGV[0]
  when "test", "prueba"
    probar_escenarios
    
  when "interactive", "interactivo"
    modo_interactivo
    
  when "help", "ayuda"
    puts "\n  AYUDA DEL SCRIPT"
    puts "=" * 60
    puts "USO: rails runner script_roles.rb [COMANDO] [PARÁMETROS]"
    puts "\nCOMANDOS DISPONIBLES:"
    puts "  test|prueba              - Ejecuta batería de pruebas (modo sandbox)"
    puts "  interactive|interactivo  - Modo interactivo para introducir datos"
    puts "  help|ayuda               - Muestra esta ayuda"
    puts "\nASIGNACIÓN DIRECTA:"
    puts "  rails runner script_roles.rb <usuario_id> <espacio_id> <assembly|process> <rol> [sandbox|real]"
    puts "  Ejemplo (sandbox): rails runner script_roles.rb 124 1 assembly admin sandbox"
    puts "  Ejemplo (real):    rails runner script_roles.rb 124 1 assembly admin real"
    
  else
    # Formato: usuario_id espacio_id tipo rol [modo]
    if ARGV.length >= 4
      usuario_id = ARGV[0].to_i
      espacio_id = ARGV[1].to_i
      tipo = ARGV[2]
      rol = ARGV[3]
      modo_sandbox = ARGV[4] != "real"  # Por defecto sandbox a menos que digan "real"
      
      asignar_rol(usuario_id, espacio_id, tipo, rol, modo_sandbox: modo_sandbox)
    else
      puts " Parámetros insuficientes. Usa 'help' para ver las opciones."
    end
  end
else
  # Sin argumentos, mostrar ayuda
  puts "\n No se especificó ningún comando"
  puts "Ejecuta: rails runner x_scripts/user_apply_roles.rb help"
end
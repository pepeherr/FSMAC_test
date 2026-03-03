# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# You can remove the 'faker' gem if you do not want Decidim seeds.
Decidim.seed!

# db/seeds.rb

puts "Creando datos de ejemplo para Decidim..."

# 1. SYSTEM ADMIN (para entrar a /system)
puts "Creando administrador del sistema..."
system_admin = Decidim::System::Admin.create!(
  email: 'system@example.com',
  password: 'decidim123456789',
  password_confirmation: 'decidim123456789'
)
puts "System admin creado: system@example.com / decidim123456789"

# 2. Crear ORGANIZATION ADMIN (para entrar a /admin)
# Primero necesitamos una organización
puts "Creando organización de ejemplo..."
organization = Decidim::Organization.create!(
  name: "Organización de ejemplo",
  host: "localhost",
  default_locale: :es,
  available_locales: [:es, :ca, :eu, :gl, :en],
  reference_prefix: "OE",
  available_authorizations: [],
  users_registration_mode: :enabled,
  tos_version: Time.current,
  badges_enabled: true,
  user_groups_enabled: true,
  send_welcome_notification: true
)

puts "Creando admin de organización..."
user = Decidim::User.create!(
  email: 'admin@example.com',
  password: 'decidim123456789',
  password_confirmation: 'decidim123456789',
  name: 'Administrador',
  nickname: 'admin',
  organization: organization,
  confirmed_at: Time.current,
  admin: true,
  roles: ["admin"]
)

# 3. USUARIO NORMAL
puts "Creando usuario normal..."
normal_user = Decidim::User.create!(
  email: 'user@example.com',
  password: 'decidim123456789',
  password_confirmation: 'decidim123456789',
  name: 'Usuario Normal',
  nickname: 'user',
  organization: organization,
  confirmed_at: Time.current,
  admin: false,
  roles: []
)

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@inimigosdabola.local")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

User.find_or_create_by!(email: admin_email) do |user|
  user.name = "Admin"
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
  user.player_type = :casual
end

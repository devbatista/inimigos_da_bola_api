admin_email = ENV.fetch("ADMIN_EMAIL", "admin@inimigosdabola.dev")
admin_password = ENV.fetch("ADMIN_PASSWORD", "inimigos123")
player_email = ENV.fetch("PLAYER_EMAIL", "player@inimigosdabola.dev")
player_password = ENV.fetch("PLAYER_PASSWORD", "inimigos123")

def log_seed(message)
  puts "[seed] #{message}"
end

if Rails.env.development?
  log_seed("Limpando dados de development...")

  [
    RefreshToken,
    ProcessedMutation,
    SessionStat,
    SkillRating,
    Attendance,
    WeeklySession,
    User
  ].each do |model|
    deleted_count = model.delete_all
    log_seed("#{model.name}: #{deleted_count} registro(s) removido(s)")
  end
else
  log_seed("Ambiente #{Rails.env}: limpeza automatica ignorada")
end

def upsert_user!(email:, password:, **attributes)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(attributes)
  user.password = password
  user.password_confirmation = password
  user.deleted_at = nil
  user.save!
  user
end

log_seed("Criando admin #{admin_email}...")
admin = upsert_user!(
  email: admin_email,
  password: admin_password,
  name: "Admin Mobile",
  admin: true,
  player_type: :monthly,
  goalkeeper: false
)

log_seed("Criando player comum #{player_email}...")
main_player = upsert_user!(
  email: player_email,
  password: player_password,
  name: "Player Mobile",
  admin: false,
  player_type: :casual,
  goalkeeper: false
)

log_seed("Criando goleiro de teste...")
goalkeeper = upsert_user!(
  email: "goleiro@inimigosdabola.dev",
  password: player_password,
  name: "Goleiro Teste",
  admin: false,
  player_type: :monthly,
  goalkeeper: true
)

log_seed("Criando mensalista de teste...")
monthly_player = upsert_user!(
  email: "mensalista@inimigosdabola.dev",
  password: player_password,
  name: "Mensalista Teste",
  admin: false,
  player_type: :monthly,
  goalkeeper: false
)

log_seed("Criando casual de teste...")
casual_player = upsert_user!(
  email: "casual@inimigosdabola.dev",
  password: player_password,
  name: "Casual Teste",
  admin: false,
  player_type: :casual,
  goalkeeper: false
)

log_seed("Criando sessao semanal atual...")
session_result = WeeklySessions::CreateCurrent.new.call
raise session_result.message if session_result.failure?

weekly_session = session_result.data
log_seed("Sessao semanal atual: #{weekly_session.id} em #{weekly_session.scheduled_at.iso8601}")

[
  [ main_player, :confirmed, nil ],
  [ goalkeeper, :confirmed, nil ],
  [ monthly_player, :declined, nil ],
  [ casual_player, :pending, nil ]
].each do |user, status, waitlist_position|
  attendance = Attendance.find_or_initialize_by(
    weekly_session: weekly_session,
    user: user,
    kind: :registered
  )
  attendance.assign_attributes(status: status, waitlist_position: waitlist_position)
  attendance.save!
  log_seed("Presenca #{status}: #{user.email}")
end

log_seed("Criando presenca avulsa...")
guest_attendance = Attendance.find_or_initialize_by(
  weekly_session: weekly_session,
  kind: :guest,
  guest_name: "Avulso Teste"
)
guest_attendance.assign_attributes(
  user: nil,
  created_by_admin: admin,
  status: :confirmed,
  waitlist_position: nil
)
guest_attendance.save!
log_seed("Presenca avulsa confirmada: #{guest_attendance.guest_name}")

log_seed("Seeds concluidos")

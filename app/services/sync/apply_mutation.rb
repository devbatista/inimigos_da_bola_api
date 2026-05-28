module Sync
  class ApplyMutation
    BLOCKED_ENTITIES = %w[attendances].freeze
    ENTITIES = {
      "users" => { model: User, blueprint: UserBlueprint, view: :sync },
      "weekly_sessions" => { model: WeeklySession, blueprint: WeeklySessionBlueprint, view: :default },
      "skill_ratings" => { model: SkillRating, blueprint: SkillRatingBlueprint, view: :default },
      "session_stats" => { model: SessionStat, blueprint: SessionStatBlueprint, view: :default }
    }.freeze
    ALLOWED_OPS = %w[create update delete].freeze

    def initialize(user:, entity:, op:, record:, mutation_id:)
      @user = user
      @entity = entity.to_s
      @op = op.to_s
      @record = record.is_a?(Hash) ? record.with_indifferent_access : {}.with_indifferent_access
      @mutation_id = mutation_id.to_s
    end

    def call
      return failure("VALIDATION_ERROR", "Header Idempotency-Key obrigatório.") if @mutation_id.blank?
      return failure("FORBIDDEN", "Presenças não aceitam sync push.") if BLOCKED_ENTITIES.include?(@entity)
      return failure("VALIDATION_ERROR", "Entidade desconhecida: #{@entity}.") unless ENTITIES.key?(@entity)
      return failure("VALIDATION_ERROR", "Operação inválida.") unless ALLOWED_OPS.include?(@op)

      if ProcessedMutation.exists?(mutation_id: @mutation_id)
        return ServiceResult.success(replay_response)
      end

      result = nil
      ActiveRecord::Base.transaction do
        ProcessedMutation.create!(mutation_id: @mutation_id, applied_at: Time.current)
        result = apply_op
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    rescue ActiveRecord::StaleObjectError
      failure("SYNC_CONFLICT", "Conflito de versão. Sincronize antes de tentar novamente.")
    end

    private

    def failure(code, message)
      ServiceResult.failure(code, message)
    end

    def apply_op
      case @op
      when "create" then handle_create
      when "update" then handle_update
      when "delete" then handle_delete
      end
    end

    def handle_update
      record = find_record
      return failure("VALIDATION_ERROR", "Registro não encontrado.") unless record

      auth_failure = authorize_op(record, :update?)
      return auth_failure if auth_failure

      version_failure = check_version(record)
      return version_failure if version_failure

      record.assign_attributes(writable_attributes)
      record.save!

      ServiceResult.success(payload(record))
    rescue ActiveRecord::RecordInvalid => e
      failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    def handle_delete
      record = find_record
      return failure("VALIDATION_ERROR", "Registro não encontrado.") unless record

      auth_failure = authorize_op(record, :destroy?)
      return auth_failure if auth_failure

      version_failure = check_version(record)
      return version_failure if version_failure

      record.soft_delete!
      ServiceResult.success(payload(record))
    end

    def handle_create
      case @entity
      when "session_stats"
        return failure("FORBIDDEN", "Apenas admin pode lançar stats.") unless @user.admin?
        build_and_create(SessionStat)
      when "skill_ratings"
        delegate_skill_rating_create
      when "weekly_sessions"
        return failure("FORBIDDEN", "Apenas admin pode criar sessões.") unless @user.admin?
        build_and_create(WeeklySession)
      else
        failure("VALIDATION_ERROR", "Operação create não suportada para #{@entity}.")
      end
    end

    def build_and_create(model_class)
      record = model_class.new(writable_attributes.merge(id_attribute))
      record.save!
      ServiceResult.success(payload(record))
    rescue ActiveRecord::RecordInvalid => e
      failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    def delegate_skill_rating_create
      evaluator_id = @record[:evaluator_user_id]
      return failure("FORBIDDEN", "Você só pode avaliar como próprio avaliador.") unless evaluator_id.to_s == @user.id

      SkillRatings::Upsert.new(
        evaluator: @user,
        evaluated_user_id: @record[:evaluated_user_id],
        score: @record[:score]
      ).call.then do |result|
        result.success? ? ServiceResult.success(payload(result.data)) : result
      end
    end

    def find_record
      ENTITIES.fetch(@entity)[:model].unscoped.find_by(id: @record[:id])
    end

    def authorize_op(record, _action)
      allowed = case @entity
      when "users" then record.id == @user.id
      when "weekly_sessions", "session_stats" then @user.admin?
      when "skill_ratings" then record.evaluator_user_id == @user.id
      end
      return nil if allowed

      failure("FORBIDDEN", "Você não tem permissão para executar esta ação.")
    end

    def check_version(record)
      client_version = @record[:version]
      return failure("SYNC_CONFLICT", "Conflito de versão. Sincronize antes de tentar novamente.") if client_version.nil?
      return failure("SYNC_CONFLICT", "Conflito de versão. Sincronize antes de tentar novamente.") if client_version.to_i != record.version

      nil
    end

    def writable_attributes
      @record.except(:id, :version, :created_at, :updated_at, :deleted_at, :encrypted_password, :jti, :password, :password_confirmation)
    end

    def id_attribute
      @record[:id].present? ? { id: @record[:id] } : {}
    end

    def payload(record)
      config = ENTITIES.fetch(@entity)
      {
        op: @op,
        entity: @entity,
        record: config[:blueprint].render_as_hash(record, view: config[:view])
      }
    end

    def replay_response
      { op: @op, entity: @entity, idempotent_replay: true }
    end
  end
end

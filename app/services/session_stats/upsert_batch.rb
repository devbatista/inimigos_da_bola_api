module SessionStats
  class UpsertBatch
    # Janela permitida para lancar/editar stats apos o racha.
    EDIT_WINDOW = 24.hours

    def initialize(weekly_session:, stats:)
      @weekly_session = weekly_session
      @stats = stats
    end

    def call
      return ServiceResult.failure("VALIDATION_ERROR", "Lista de estatísticas inválida.") unless valid_list?

      if locked?
        return ServiceResult.failure(
          "STATS_LOCKED",
          "As estatísticas não podem mais ser editadas após 24h do racha."
        )
      end

      unless invalid_user_ids.empty?
        return ServiceResult.failure(
          "STATS_USER_NOT_IN_SESSION",
          "Só é possível registrar estatísticas para jogadores cadastrados presentes no racha."
        )
      end

      records = ActiveRecord::Base.transaction do
        @stats.map { |entry| upsert_one(entry) }
      end

      ServiceResult.success(records)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure("VALIDATION_ERROR", e.record.errors.full_messages.to_sentence)
    end

    private

    def valid_list?
      @stats.is_a?(Array) && @stats.any?
    end

    def locked?
      Time.current > @weekly_session.scheduled_at + EDIT_WINDOW
    end

    # Avulsos sem cadastro nao tem user_id, entao so jogadores com presenca
    # registrada no racha podem receber stats.
    def invalid_user_ids
      requested = @stats.map { |entry| entry[:user_id] }.compact.uniq
      registered = @weekly_session.attendances.active.registered.pluck(:user_id)
      requested - registered
    end

    def upsert_one(entry)
      stat = @weekly_session.session_stats.active.find_or_initialize_by(user_id: entry[:user_id])
      stat.goals = entry[:goals]
      stat.assists = entry[:assists]
      stat.save!
      stat
    end
  end
end

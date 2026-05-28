module Sync
  class PullChanges
    ENTITIES = {
      "users" => { model: User, blueprint: UserBlueprint, view: :sync },
      "weekly_sessions" => { model: WeeklySession, blueprint: WeeklySessionBlueprint, view: :default },
      "attendances" => { model: Attendance, blueprint: AttendanceBlueprint, view: :default },
      "session_stats" => { model: SessionStat, blueprint: SessionStatBlueprint, view: :default }
    }.freeze

    def initialize(since:, entities:)
      @since = since
      @entities = entities
    end

    def call
      requested = requested_entities
      return ServiceResult.failure("VALIDATION_ERROR", invalid_entity_message(requested)) if invalid_entities?(requested)

      since_time = parse_since
      return ServiceResult.failure("VALIDATION_ERROR", "Parâmetro 'since' inválido.") if @since.present? && since_time.nil?

      payload = {
        server_time: Time.current.utc.iso8601,
        entities: requested.each_with_object({}) do |entity, hash|
          hash[entity] = serialize(entity, since_time)
        end
      }

      ServiceResult.success(payload)
    end

    private

    def requested_entities
      return ENTITIES.keys if @entities.blank?

      @entities.map(&:to_s).map(&:strip).reject(&:blank?)
    end

    def invalid_entities?(requested)
      (requested - ENTITIES.keys).any?
    end

    def invalid_entity_message(requested)
      unknown = (requested - ENTITIES.keys).first
      "Entidade desconhecida: #{unknown}."
    end

    def parse_since
      return nil if @since.blank?

      Time.iso8601(@since.to_s).utc
    rescue ArgumentError
      nil
    end

    def serialize(entity, since_time)
      config = ENTITIES.fetch(entity)
      scope = config.fetch(:model).unscoped
      scope = scope.where("updated_at > ?", since_time) if since_time
      config.fetch(:blueprint).render_as_hash(scope.order(:updated_at), view: config.fetch(:view))
    end
  end
end

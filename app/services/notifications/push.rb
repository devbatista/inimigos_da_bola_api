module Notifications
  # Resolve a audiencia em tokens FCM, monta o payload (notificacao visivel ou
  # data message silenciosa) e entrega o push. A entrega real no FCM ainda e um
  # stub que apenas loga; o ponto de integracao HTTP fica isolado em #deliver.
  class Push
    AUDIENCES = %i[all admins user].freeze

    def initialize(audience:, title: nil, body: nil, data: {}, user: nil)
      @audience = audience.to_sym
      @title = title
      @body = body
      @data = (data || {}).transform_keys(&:to_s)
      @user = user
    end

    def call
      return ServiceResult.failure("VALIDATION_ERROR", "Audiência inválida.") unless AUDIENCES.include?(@audience)
      return ServiceResult.failure("VALIDATION_ERROR", "Audiência 'user' exige um usuário.") if @audience == :user && @user.nil?

      tokens = recipient_tokens
      payload = build_payload

      deliver(tokens, payload) if tokens.any?

      ServiceResult.success(tokens_count: tokens.size, silent: silent?, payload: payload)
    end

    private

    def recipient_tokens
      scope =
        case @audience
        when :all then User.active.where.not(fcm_token: nil)
        when :admins then User.active.where(admin: true).where.not(fcm_token: nil)
        when :user then User.active.where(id: @user.id).where.not(fcm_token: nil)
        end

      scope.pluck(:fcm_token)
    end

    # Sem title/body a mensagem e silenciosa: serve apenas para disparar o sync
    # no app (data message sem notificacao visivel).
    def silent?
      @title.blank? && @body.blank?
    end

    def build_payload
      payload = { data: @data }
      payload[:notification] = { title: @title, body: @body } unless silent?
      payload
    end

    # Stub de entrega. A integracao real com o FCM HTTP v1 (credenciais,
    # request HTTP e tratamento de tokens invalidos) entra exatamente aqui.
    def deliver(tokens, payload)
      Rails.logger.info(
        "[Notifications::Push] audience=#{@audience} silent=#{silent?} " \
        "tokens=#{tokens.size} payload=#{payload.inspect}"
      )
    end
  end
end

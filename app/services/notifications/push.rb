module Notifications
  # Stub de envio de push. A integracao real com FCM sera feita na spec 11.
  # Mantemos o ponto de chamada (audience/title/body/data) para que jobs e
  # services ja consigam disparar notificacoes pelo caminho final.
  class Push
    AUDIENCES = %i[all admins user].freeze

    def initialize(audience:, title:, body:, data: {}, user: nil)
      @audience = audience
      @title = title
      @body = body
      @data = data
      @user = user
    end

    def call
      return ServiceResult.failure("VALIDATION_ERROR", "Audiencia invalida.") unless AUDIENCES.include?(@audience)

      Rails.logger.info(
        "[Notifications::Push] audience=#{@audience} title=#{@title.inspect} " \
        "body=#{@body.inspect} data=#{@data.inspect} user_id=#{@user&.id.inspect}"
      )
      ServiceResult.success(nil)
    end
  end
end

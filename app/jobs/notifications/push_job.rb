module Notifications
  # Wrapper assincrono de Notifications::Push. Os services chamam
  # perform_later para não bloquear a request HTTP com o envio do FCM.
  class PushJob < ApplicationJob
    queue_as :default

    def perform(audience:, title: nil, body: nil, data: {}, user_id: nil)
      user = user_id.present? ? User.active.find_by(id: user_id) : nil

      Notifications::Push.new(
        audience: audience,
        title: title,
        body: body,
        data: data || {},
        user: user
      ).call
    end
  end
end

module Auth
  class FailureApp < Devise::FailureApp
    def respond
      self.status = 401
      self.content_type = "application/json"
      self.response_body = error_payload.to_json
    end

    private

    def error_payload
      if token_expired?
        { error: { code: "token_expired", message: "Token expirado." } }
      else
        { error: { code: "UNAUTHORIZED", message: "Você precisa estar autenticado." } }
      end
    end

    # Detecta JWT expirado para devolver o code padronizado para o app mobile
    def token_expired?
      header = request.headers["Authorization"].to_s
      return false unless header.start_with?("Bearer ")

      token = header.split(" ", 2).last
      Warden::JWTAuth::TokenDecoder.new.call(token)
      false
    rescue ::JWT::ExpiredSignature
      true
    rescue ::JWT::DecodeError
      false
    end
  end
end

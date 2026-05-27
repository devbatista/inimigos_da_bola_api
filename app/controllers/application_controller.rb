class ApplicationController < ActionController::API
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end

  def render_forbidden
    render_error("FORBIDDEN", "Você não tem permissão para executar esta ação.", :forbidden)
  end

  def render_not_found
    render_error("NOT_FOUND", "Registro não encontrado.", :not_found)
  end
end

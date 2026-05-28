class AuthMailer < ApplicationMailer
  def reset_password(user, token)
    @user = user
    @token = token

    mail(to: user.email, subject: "Redefinicao de senha")
  end

  def invitation(user, token)
    @user = user
    @token = token

    mail(to: user.email, subject: "Convite para o Inimigos da Bola")
  end
end

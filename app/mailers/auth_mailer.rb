class AuthMailer < ApplicationMailer
  def reset_password(user, token)
    @user = user
    @token = token

    mail(to: user.email, subject: "Redefinicao de senha")
  end
end

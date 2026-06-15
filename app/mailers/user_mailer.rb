class UserMailer < ApplicationMailer
  default from: ENV["GMAIL_USER"].presence || "no-reply@astreintes.local"

  def invitation(user)
    @user  = user
    token  = user.generate_token_for(:invitation)
    @url   = accept_invitation_url(token: token, host: mailer_host)
    mail(to: user.email, subject: "Invitation à rejoindre l'application d'astreinte")
  end

  private

  def mailer_host
    ENV["APP_HOST"].presence || "localhost:3000"
  end
end

# app/mailers/slot_mailer.rb
class SlotMailer < ApplicationMailer
  default from: ENV["GMAIL_USER"].presence || "no-reply@astreintes.local"

  def notify(slot)
    @slot = slot
    @user = slot.user
    mail(to: @user.email, subject: "🚨 Vous êtes requis en astreinte")
  end

  def assigned(slot)
    @slot = slot
    @user = slot.user
    mail(to: @user.email, subject: "📅 Astreinte assignée")
  end

  # Une nouvelle astreinte est disponible (envoyé aux collaborateurs concernés).
  def new_available(slot, recipient)
    @slot = slot
    @user = recipient
    mail(to: recipient.email, subject: "🆕 Nouvelle astreinte disponible")
  end

  # Une demande de prise d'astreinte attend validation (envoyé aux managers).
  def request_submitted(slot, manager)
    @slot = slot
    @manager = manager
    @requester = slot.requested_by
    mail(to: manager.email, subject: "🕓 Demande d'astreinte à valider")
  end

  # La demande du collaborateur a été validée.
  def request_validated(slot)
    @slot = slot
    @user = slot.user
    mail(to: @user.email, subject: "✅ Votre astreinte a été validée")
  end

  # La demande du collaborateur a été refusée.
  def request_rejected(slot, user)
    @slot = slot
    @user = user
    mail(to: user.email, subject: "❌ Votre demande d'astreinte a été refusée")
  end

  # Une astreinte a été supprimée (le slot n'existe plus : données primitives).
  def slot_deleted(user, details)
    @user = user
    @details = details
    mail(to: user.email, subject: "🗑️ Une de vos astreintes a été supprimée")
  end
end
class UsersController < ApplicationController
  before_action :require_admin,   only: %i[change_role disable enable destroy]
  before_action :require_manager, only: %i[new create change_service]

  # Formulaire d'invitation d'un nouvel utilisateur.
  def new
    @user = User.new
    @services = assignable_services
    @roles = invitable_roles
  end

  # Crée l'utilisateur (sans mot de passe choisi) et lui envoie une invitation.
  def create
    role = invitable_roles.include?(params[:role]) ? params[:role] : nil
    unless role
      prepare_new_form(error: "Veuillez sélectionner un rôle valide.")
      return render :new, status: :unprocessable_entity
    end

    @user = User.new(
      first_name: params[:first_name],
      last_name:  params[:last_name],
      email:      params[:email].to_s.downcase,
      role:       role,
      service_id: target_service_id,
      active:     false,
      password:   SecureRandom.hex(24) # provisoire : remplacé à l'acceptation
    )

    if @user.save
      UserMailer.invitation(@user).deliver_later
      redirect_to "/dashboard/users", notice: "Invitation envoyée à #{@user.email}."
    else
      prepare_new_form(error: @user.errors.full_messages.to_sentence)
      render :new, status: :unprocessable_entity
    end
  end

  def change_service
    user = User.find(params[:id])
    user.update!(service_id: params[:service_id].presence)
    redirect_back fallback_location: "/dashboard/users", notice: "Service mis à jour."
  end

  # Le rôle "admin" est unique et créé via /register_admin uniquement.
  CHANGEABLE_ROLES = %w[collaborateur responsable].freeze

  def change_role
    return head :forbidden unless CHANGEABLE_ROLES.include?(params[:role])
    user = User.find(params[:id])
    user.update!(role: params[:role])
    head :ok
  end

  def disable
    user = User.find(params[:id])
    user.update!(active: false)
    head :ok
  end

  def enable
    user = User.find(params[:id])
    user.update!(active: true)
    head :ok
  end

  def destroy
    user = User.find(params[:id])
    user.destroy!
    head :ok
  end

  def profile

    @page = "profile"
  end

  def preferences
    @page = "préférences"
  end


  def update_preferences
    channels = Array(params[:notification_channels]).map(&:to_s) & User::NOTIFICATION_CHANNELS
    periods = Array(params[:notification_periods]).map(&:to_s) & User::NOTIFICATION_PERIODS
    theme    = params[:theme].to_s

    unless User::THEMES.include?(theme)
      return redirect_to "/preferences", alert: "Thème invalide."
    end

    current_user.update!(
      notification_channels: channels,
      notification_periods: periods,
      theme:                 theme,
      discord_user_id:       params[:discord_user_id].to_s.strip.presence
    )
    redirect_to "/preferences", notice: "Préférences enregistrées."
  end


  def unlink_telegram
    current_user.update!(telegram_chat_id: nil)
    redirect_to "/preferences", notice: "Telegram délié."
  end

  def security

    @page = "security"
  end

  def update_password
    unless current_user.authenticate(params[:current_password])
      return render json: { error: "Mot de passe actuel incorrect" }, status: :unprocessable_entity
    end

    if current_user.update(password_params)
      render json: { message: "Mot de passe mis à jour" }, status: :ok
    else
      render json: {
        error: current_user.errors.full_messages.to_sentence
      }, status: :unprocessable_entity
    end
  end

  # Envoie un message de test sur le canal demandé.
  def test_notification
    channel = params[:channel].to_s
    message = "Test depuis Astreintes — #{Time.current.strftime('%H:%M')}"

    case channel
    when "slack"    then SlackNotifier.send_dm(slack_uid: current_user.slack_uid, message: message)
    when "discord"  then DiscordNotifier.send_dm(discord_user_id: current_user.discord_user_id, message: message)
    when "telegram" then TelegramNotifier.send_message(chat_id: current_user.telegram_chat_id, message: message)
    else return redirect_to "/preferences", alert: "Canal inconnu."
    end

    redirect_to "/preferences", notice: "Test envoyé sur #{channel}."
  end

  private

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def prepare_new_form(error:)
    @user = User.new
    @services = assignable_services
    @roles = invitable_roles
    @error = error
  end

  # Services qu'on peut affecter selon le rôle de l'invitant.
  def assignable_services
    return Service.order(:name) if current_user.global_manager?
    Service.where(id: current_user.service_id)
  end

  # admin -> responsable/collab ; responsable -> collab uniquement.
  # Le rôle admin se crée via /register_admin ou change_role.
  def invitable_roles
    if current_user.admin?
      %w[collaborateur responsable]
    else
      %w[collaborateur]
    end
  end

  # Le responsable verrouille le service sur le sien.
  def target_service_id
    return current_user.service_id if current_user.responsable?
    params[:service_id].presence
  end

end
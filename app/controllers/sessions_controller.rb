class SessionsController < ApplicationController
  skip_before_action :require_login,           only: %i[login create register_admin bootstrap_admin saml_callback]
  skip_before_action :verify_authenticity_token, only: %i[saml_callback]
  before_action :redirect_if_admin_exists, only: %i[register_admin bootstrap_admin]
  before_action :redirect_if_no_admin,     only: %i[login create]
  before_action :redirect_if_logged_in,    only: %i[login]
  before_action :require_admin,            only: %i[register new]

  # /register : l'admin se crée uniquement via /register_admin (bootstrap).
  ALLOWED_USER_ROLES = %w[responsable collaborateur].freeze

  def login; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user&.authenticate(params[:password])
      if user.active?
        session[:user_id] = user.id
        redirect_to "/slots", notice: "Bienvenue #{user.first_name} !"
      else
        flash.now[:alert] = "Votre compte a été désactivé. Veuillez contacter votre administrateur."
        render :login, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Email ou mot de passe incorrect."
      render :login, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to "/login", notice: "Vous êtes déconnecté."
  end

  def register; end

  def register_admin; end

  # POST /register_admin : crée le premier admin. Rôle forcé côté serveur.
  def bootstrap_admin
    return render_password_mismatch(:register_admin) if password_mismatch?

    user = build_user(role: "admin")

    if user.save
      session[:user_id] = user.id
      redirect_to "/dashboard", notice: "Compte administrateur créé. Bienvenue !"
    else
      @error = user.errors.full_messages.to_sentence
      render :register_admin, status: :unprocessable_entity
    end
  end

  # POST /register : admin crée un responsable ou collaborateur.
  def new
    return render_password_mismatch(:register) if password_mismatch?

    role = ALLOWED_USER_ROLES.include?(params[:role]) ? params[:role] : nil
    unless role
      @error = "Veuillez sélectionner un rôle valide."
      return render :register, status: :unprocessable_entity
    end

    user = build_user(role: role)

    if user.save
      redirect_to "/dashboard", notice: "Utilisateur #{user.full_name} créé."
    else
      @error = user.errors.full_messages.to_sentence
      render :register, status: :unprocessable_entity
    end
  end

  private

  def build_user(role:)
    User.new(
      email: params[:email].to_s.downcase,
      first_name: params[:firstName],
      last_name: params[:lastName],
      password: params[:password],
      role: role,
      active: true
    )
  end

  def password_mismatch?
    params[:password] != params[:retypePassword]
  end

  def render_password_mismatch(template)
    @password_error = "Les mots de passe ne correspondent pas."
    render template, status: :unprocessable_entity
  end

  def redirect_if_admin_exists
    redirect_to(logged_in? ? "/dashboard" : "/login", alert: "Action non autorisée.") if admin_exists?
  end

  def redirect_if_no_admin
    redirect_to "/register_admin" unless admin_exists?
  end

  def redirect_if_logged_in
    redirect_to "/slots" if logged_in?
  end

  def saml_callback
    auth = request.env["omniauth.auth"]
    email = auth&.info&.email.to_s.downcase

    if email.blank?
      redirect_to "/login", alert: "Impossible de récupérer votre email depuis le fournisseur SSO."
      return
    end

    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      names         = auth.info.name.to_s.split(" ", 2)
      user.first_name = auth.info.first_name.presence || names.first.presence || "Nouveau"
      user.last_name  = auth.info.last_name.presence  || names.second.presence || "Utilisateur"
      user.role     = "collaborateur"
      user.active   = true
      user.password = SecureRandom.hex(32)
    end

    if user.save
      if user.active?
        session[:user_id] = user.id
        redirect_to "/slots", notice: "Bienvenue #{user.first_name} !"
      else
        redirect_to "/login", alert: "Votre compte a été désactivé. Contactez votre administrateur."
      end
    else
      redirect_to "/login", alert: "Connexion SSO impossible : #{user.errors.full_messages.to_sentence}"
    end
  rescue StandardError => e
    Rails.logger.error("[saml_callback] #{e.class}: #{e.message}")
    redirect_to "/login", alert: "Erreur lors de la connexion SSO."
  end
end

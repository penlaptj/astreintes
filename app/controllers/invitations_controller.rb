class InvitationsController < ApplicationController
  # Flux public : l'invité n'est pas encore connecté.
  skip_before_action :require_login
  before_action :set_user_from_token

  # Écran de définition du mot de passe.
  def edit
    redirect_to "/login", alert: "Lien d'invitation invalide ou expiré." if @user.nil?
  end

  def update
    return redirect_to("/login", alert: "Lien d'invitation invalide ou expiré.") if @user.nil?

    if params[:password].blank? || params[:password] != params[:password_confirmation]
      @error = "Les mots de passe ne correspondent pas."
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(password: params[:password], active: true)
      session[:user_id] = @user.id
      redirect_to "/slots", notice: "Bienvenue ! Votre compte est activé."
    else
      @error = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_from_token
    @user = User.find_by_token_for(:invitation, params[:token])
  end
end

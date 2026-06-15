class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login, :set_unread_notifications_count

  helper_method :current_user, :logged_in?, :has_unread_notification

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def admin_exists?
    User.exists?(role: "admin")
  end

  def require_login
    return if logged_in?

    if !admin_exists?
      redirect_to "/register_admin"
    else
      redirect_to "/login", alert: "Veuillez vous connecter."
    end
  end

  def require_admin
    redirect_to "/slots", alert: "Accès refusé." unless current_user&.admin?
  end

  # admin OU responsable de service.
  def require_manager
    redirect_to "/slots", alert: "Accès refusé." unless current_user&.manager?
  end

  def has_unread_notification
    Noticed::Notification.where(recipient: current_user).unread.exists?
  end

  def set_unread_notifications_count
    @unread_count = Noticed::Notification.where(recipient: current_user).unread.count rescue 0
  end
end

class DashboardsController < ApplicationController
  before_action :require_manager
  before_action :load_dashboard_data,
                only: [:dashboard_users, :dashboard_astreintes, :dashboard_history, :dashboard_recaps]

  def load_dashboard_data
    @services = Service.order(:name)
    @users = current_user.manageable_users.order(:id)
    @total_users = @users.count
    case params[:role]
    when "collaborateur"
      @users = @users.collaborateur
    when "responsable"
      @users = @users.responsable
    when "admin"
      @users = @users.admin
    end
    @slots = current_user.manageable_slots.upcoming.or(current_user.manageable_slots.in_progress).order(:starts_at)
    @past_slots = current_user.manageable_slots.passed.order(:starts_at).reverse_order
    @total_astreintes = @slots.count
    @total_past_slots = @past_slots.count
  end

  def dashboard_users
  end

  def dashboard_astreintes
    @is_history = false
  end

  def dashboard_recaps
    load_recap_data
  end

  def dashboard_history
    @is_history = true
  end

  def export
    load_recap_data
    respond_to do |format|
      format.xlsx do
        filename = "recap_astreintes_#{@starts_at.to_date}_#{@ends_at.to_date}.xlsx"
        response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      end
    end
  end

  def users
    @total_users = User.count
    @users= User.all.order(:id)
  end

  def astreintes
    @total_astreintes = Slot.count
    @slots = Slot.all.order(:starts_at)
  end

  private

  def load_recap_data
    @users = current_user.manageable_users.order(:last_name, :first_name)
    @starts_at = parse_time(params[:starts_at]) || Time.current.beginning_of_month
    @ends_at   = parse_time(params[:ends_at])   || Time.current.end_of_month

    slots = Slot.where(user_id: @users.select(:id))
                .where("starts_at >= ? AND ends_at <= ?", @starts_at, @ends_at)
                .order(:starts_at)
    @slots_by_user = @users.each_with_object({}) { |u, h| h[u.id] = [] }
    slots.each { |s| @slots_by_user[s.user_id] << s }
  end

  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end

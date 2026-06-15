class NotificationsController < ApplicationController

  before_action :load_notifications_sidebar_data,
                only: [:index, :show_by_sender, :sidebar, :system]

  SYSTEM_SENDER_KEY = "system".freeze

  def load_notifications_sidebar_data
    @notifications = Noticed::Notification.where(recipient: current_user).includes(:event)

    @system_notifications = @notifications.select { |n| n.event.params[:sender_id].blank? }
    @system_unread        = @system_notifications.count(&:unread?)

    user_notifications = @notifications - @system_notifications
    @sender_ids = user_notifications
      .map { |n| n.event.params[:sender_id] }
      .compact
      .uniq

    @unread_by_sender = user_notifications
      .select(&:unread?)
      .group_by { |n| n.event.params[:sender_id] }
      .transform_values(&:count)

    @senders = User.where(id: @sender_ids)
                   .index_by(&:id)
                   .values_at(*@sender_ids)
                   .compact
  end

  def index
    if @senders.any?
      @sender = @senders.first
      @notifications_by_user = sorted_unfiltered_notifications_for(@sender.id)
      mark_read_for_sender(@sender.id)
    elsif @system_notifications.any?
      return redirect_to "/notifications/system"
    else
      @sender = nil
      @notifications_by_user = []
    end
  end

  def show_by_sender
    @sender = User.find(params[:sender_id])
    @notifications_by_user = sorted_unfiltered_notifications_for(@sender.id)
    mark_read_for_sender(@sender.id)
    render :index
  end

  def system
    @sender = nil
    @system_view = true
    @notifications_by_user = @system_notifications.sort_by(&:created_at).reverse
    @system_notifications.each(&:mark_as_read)
    render :index
  end

  def markAsRead
    Noticed::Notification.where(recipient: current_user).find(params[:notification_id]).mark_as_read!
    head :ok
  end

  def sidebar
    render partial: "notifications/sidebar"
  end

  def create
    receiver = User.find(params[:receiver_id])
    slot     = Slot.find(params[:slot_id])

    AstreinteNotifier.with(
      notification_type: params[:notification_type],
      sender_id:         current_user.id,
      sender_name:       current_user.full_name,
      slot_id:           slot.id,
      slot_starts_at:    slot.starts_at,
      slot_ends_at:      slot.ends_at,
      slot_compensation: slot.compensation_label,
      receiver_name:     receiver.first_name
    ).deliver(receiver)

    head :ok
  end

  private

  def sorted_unfiltered_notifications_for(sender_id)
    Noticed::Notification.where(recipient: current_user)
      .includes(:event)
      .select { |n| n.event.params[:sender_id].to_s == sender_id.to_s }
      .sort_by(&:created_at)
      .reverse
  end

  def mark_read_for_sender(sender_id)
    Noticed::Notification.where(recipient: current_user)
      .includes(:event)
      .select { |n|
        n.event.params[:sender_id].to_s == sender_id.to_s &&
        n.event.params[:notification_type] != "swap_request"
      }
      .each(&:mark_as_read)
  end
end

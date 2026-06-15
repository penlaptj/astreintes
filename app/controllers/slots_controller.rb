class SlotsController < ApplicationController
  before_action :require_manager,
                only: %i[new create edit update destroy notify assign validation validate_request reject_request]

  def slots
    scope = Slot.available.order(:starts_at)
    # Un collaborateur ne voit que les créneaux de son service (ou sans service).
    unless current_user.manager?
      scope = scope.where(service_id: [nil, current_user.service_id])
    end
    @slots = scope
  end

  def take
    slot = Slot.find(params[:id])

    if slot.available?
      slot.update!(requested_by: current_user, assignment_state: "pending")
      notify_request_submitted(slot)
      redirect_to "/slots", notice: "Demande envoyée — en attente de validation."
    else
      redirect_to "/slots", alert: "Ce créneau n'est plus disponible."
    end
  end

  # File d'attente des demandes à valider (managers).
  def validation
    @slots = current_user.manageable_slots
                         .pending
                         .includes(:requested_by, :service)
                         .order(:starts_at)
  end

  def validate_request
    slot = Slot.find(params[:id])
    return head :forbidden unless can_manage_slot?(slot)

    if slot.pending? && slot.requested_by_id
      slot.update!(user_id: slot.requested_by_id, assignment_state: "assigned", requested_by: nil)
      notify_request_validated(slot)
    end
    redirect_back fallback_location: "/slots/validation", notice: "Astreinte validée."
  end

  def reject_request
    slot = Slot.find(params[:id])
    return head :forbidden unless can_manage_slot?(slot)

    requester = slot.requested_by
    slot.update!(assignment_state: "available", requested_by: nil)
    notify_request_rejected(slot, requester)
    redirect_back fallback_location: "/slots/validation", notice: "Demande refusée."
  end

  def index
    @user = User.find(params[:user_id])
    @slots = @user.slots.order(:starts_at)

    if params[:starts_at].present? && params[:ends_at].present?
      @slots = @slots.where(
        "starts_at >= ? AND ends_at <= ?",
        params[:starts_at],
        params[:ends_at]
      )
    end

    render partial: "slots/slot_recap", locals: { slots: @slots, user: @user }
  end

  def export_user
    @user = User.find(params[:user_id])
    @starts_at = parse_time(params[:starts_at]) || Time.current.beginning_of_month
    @ends_at   = parse_time(params[:ends_at])   || Time.current.end_of_month
    @slots = @user.slots
                  .where("starts_at >= ? AND ends_at <= ?", @starts_at, @ends_at)
                  .order(:starts_at)

    respond_to do |format|
      format.xlsx do
        filename = "recap_#{@user.last_name.to_s.parameterize}_#{@starts_at.to_date}_#{@ends_at.to_date}.xlsx"
        response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      end
    end
  end

  def new
    @services = assignable_services
  end

  def create
    slot = Slot.new(
      starts_at: params[:slot][:starts_at],
      ends_at: params[:slot][:ends_at],
      slot_type: params[:slot][:slot_type],
      description: params[:slot][:description],
      compensation_money: params[:slot][:compensation_money],
      compensation_days: params[:slot][:compensation_days],
      service_id: resolved_service_id(params[:slot][:service_id])
    )

    if slot.save
      notify_new_available(slot)
      redirect_to "/dashboard", notice: "Astreinte créée."
    else
      @services = assignable_services
      redirect_to "/slots/new", alert: slot.errors.full_messages.to_sentence
    end
  end

  def mes_astreintes
    @slots = current_user.slots

    case params[:status]
    when "in_progress"
      @slots = @slots.in_progress
    when "passed"
      @slots = @slots.passed
    when "upcoming"
      @slots = @slots.upcoming
    end

    case params[:type]
    when "euro"
      @slots = @slots.euro_compensation
    when "jours"
      @slots = @slots.day_compensation
    end

    case params[:sort]
    when "date"
      @slots = @slots.by_date
    when "duration"
      @slots = @slots.by_duration
    when "compensation"
      @slots = @slots.by_compensation
    else
      @slots = @slots.by_date
    end

    @users = User.order(:id)
  end

  # Libère une astreinte : auto-retrait du collab assigné, ou désassignation par un manager.
  def release
    slot = Slot.find(params[:id])

    self_release = slot.user_id.present? && slot.user_id == current_user.id
    unless self_release || can_manage_slot?(slot)
      return redirect_back fallback_location: "/slots", alert: "Action non autorisée."
    end

    previous_assignee = slot.user
    slot.update!(user_id: nil, assignment_state: "available", requested_by: nil)

    if previous_assignee && previous_assignee.id != current_user.id
      notify_slot_unassigned(previous_assignee, slot)
    end

    redirect_back fallback_location: "/mes_astreintes", notice: "Astreinte libérée."
  end

  def swap

  end

  def edit
    @slot = Slot.find(params[:id])
    @services = assignable_services
  end

  def update
    @slot = Slot.find(params[:id])
    @slot.update!(
      starts_at: params[:slot][:starts_at],
      ends_at: params[:slot][:ends_at],
      slot_type: params[:slot][:slot_type],
      description: params[:slot][:description],
      compensation_money: params[:slot][:compensation_money],
      compensation_days: params[:slot][:compensation_days],
      service_id: resolved_service_id(params[:slot][:service_id])
    )
    redirect_to "/dashboard"
  end

  def destroy
    slot = Slot.find(params[:id])
    assignee = slot.user
    details = {
      starts_at: slot.starts_at,
      ends_at: slot.ends_at,
      description: slot.description.to_s
    }
    slot.destroy!
    notify_slot_deleted(assignee, details)
    redirect_to "/dashboard"
  end

  def calendar
    if current_user.manager?
      @users = current_user.manageable_users.order(:id)
      @slots = current_user.manageable_slots.includes(:user)
    else
      # Collaborateur : ses créneaux + ceux disponibles de son service (ou sans service).
      @users = User.where(id: current_user.id)
      @slots = Slot.includes(:user).where(
        "user_id = :uid OR (assignment_state = 'available' AND (service_id IS NULL OR service_id = :sid))",
        uid: current_user.id, sid: current_user.service_id
      )
    end

    @slots_json = @slots.map do |slot|
      title =
        if slot.user_id == current_user.id
          "Mon astreinte"
        elsif slot.user
          slot.user.full_name
        else
          "Non assigné"
        end

      {
        id: slot.id,
        title: title,
        start: slot.starts_at.iso8601,
        end: slot.ends_at.iso8601,
        color: slot_color(slot),
        userId: slot.user_id,
        description: slot.description.to_s
      }
    end.to_json
  end


  def assign
    slot = Slot.find(params[:id])
    user = User.find(params[:user_id])
    return head :forbidden unless can_manage_slot?(slot)

    slot.update!(user: user, assignment_state: "assigned", requested_by: nil)
    SlotMailer.assigned(slot).deliver_later
    head :ok
  end

  
  # Action "Notifier" du menu astreintes — l'admin convoque immédiatement
  # le collaborateur assigné. Email asynchrone + notification in-app temps réel.
  def notify
    slot = Slot.find(params[:id])

    unless slot.user
      redirect_back fallback_location: "/dashboard",
                    alert: "Cette astreinte n'a aucun collaborateur assigné."
      return
    end

    NotifySlotJob.perform_later(slot.id)

    AstreinteNotifier.with(
      notification_type: "urgent_call",
      sender_id:         current_user.id,
      sender_name:       current_user.full_name,
      slot_id:           slot.id,
      slot_starts_at:    slot.starts_at,
      slot_ends_at:      slot.ends_at,
      slot_compensation: slot.compensation_label,
      slot_description:  slot.description,
      receiver_name:     slot.user.first_name
    ).deliver(slot.user)

    redirect_back fallback_location: "/dashboard",
                  notice: "#{slot.user.full_name} a été notifié(e)."
  end

  private

  def parse_time(value)
    return nil if value.blank?
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  # Services proposables dans le formulaire d'astreinte.
  def assignable_services
    if current_user.global_manager?
      Service.order(:name)
    elsif current_user.responsable? && current_user.service
      Service.where(id: current_user.service_id)
    else
      Service.none
    end
  end

  # Le responsable est verrouillé sur son service ; le manager global choisit.
  def resolved_service_id(param)
    return current_user.service_id if current_user.responsable?
    param.presence
  end

  def can_manage_slot?(slot)
    current_user.global_manager? ||
      (current_user.responsable? && current_user.service_id.present? &&
        slot.service_id == current_user.service_id)
  end

  def slot_color(slot)
    case slot.assignment_state
    when "pending"  then "#f59e0b"
    when "assigned" then helpers.color_for_user(slot.user_id)
    else "#6366f1"
    end
  end

  def color_for_user(user_id)
    return "#10b981" if user_id.blank?
    USER_PALETTE[user_id.to_i % USER_PALETTE.size]
  end

  # ---------- Notifications e-mail (Phase 5) ----------

  def notify_new_available(slot)
    new_available_recipients(slot).find_each do |user|
      SlotMailer.new_available(slot, user).deliver_later
    end
  end

  def notify_request_submitted(slot)
    request_managers(slot).find_each do |manager|
      SlotMailer.request_submitted(slot, manager).deliver_later
    end
  end

  def notify_request_validated(slot)
    return unless slot.user
    SlotMailer.request_validated(slot).deliver_later
  end

  def notify_request_rejected(slot, user)
    return unless user
    SlotMailer.request_rejected(slot, user).deliver_later
  end

  def notify_slot_deleted(user, details)
    return unless user
    SlotMailer.slot_deleted(user, details).deliver_later
  end

  # Réutilise slot_deleted (info utile identique). Échec silencieux.
  def notify_slot_unassigned(user, slot)
    details = {
      starts_at:   slot.starts_at,
      ends_at:     slot.ends_at,
      description: slot.description.to_s
    }
    SlotMailer.slot_deleted(user, details).deliver_later
  rescue StandardError => e
    Rails.logger.warn("[notify_slot_unassigned] #{e.message}")
  end

  def new_available_recipients(slot)
    scope = User.active.collaborateur
    scope = scope.where(service_id: slot.service_id) if slot.service_id
    scope
  end

  def request_managers(slot)
    if slot.service
      slot.service.managers
    else
      # Sans service : seuls les admins valident.
      User.active.where(role: "admin")
    end
  end
end

class NotifySlotJob < ApplicationJob
  queue_as :default

  def perform(slot_id)
    slot = Slot.find(slot_id)
    return unless slot.user

    SlotMailer.notify(slot).deliver_now
  end
end

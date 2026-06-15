require "test_helper"

class SlotTest < ActiveSupport::TestCase
  def build_slot(attrs = {})
    Slot.create!({ starts_at: 2.days.from_now, ends_at: 2.days.from_now + 4.hours }.merge(attrs))
  end

  test "new slot defaults to available state" do
    slot = build_slot
    assert slot.available?
    assert_not slot.pending?
    assert_not slot.assigned?
  end

  test "compensation_label with money only" do
    slot = build_slot(compensation_money: 150)
    assert_equal "150 €", slot.compensation_label
  end

  test "compensation_label with days only keeps the half" do
    slot = build_slot(compensation_days: 0.5)
    assert_equal "0.5 Jours", slot.compensation_label
  end

  test "compensation_label strips trailing zero for whole days" do
    slot = build_slot(compensation_days: 2)
    assert_equal "2 Jours", slot.compensation_label
  end

  test "compensation_label with both money and days" do
    slot = build_slot(compensation_money: 150, compensation_days: 0.5)
    assert_equal "150 € + 0.5 Jours", slot.compensation_label
  end

  test "compensation_label with nothing" do
    assert_equal "—", build_slot.compensation_label
  end

  test "state scopes" do
    available = build_slot(assignment_state: "available")
    pending   = build_slot(assignment_state: "pending")
    assigned  = build_slot(assignment_state: "assigned")

    assert_includes Slot.available.ids, available.id
    assert_includes Slot.pending.ids, pending.id
    assert_includes Slot.assigned.ids, assigned.id
    assert_not_includes Slot.available.ids, pending.id
  end

  test "compensation scopes select slots having that compensation" do
    money = build_slot(compensation_money: 100)
    days  = build_slot(compensation_days: 1)
    both  = build_slot(compensation_money: 50, compensation_days: 1)

    assert_includes Slot.euro_compensation.ids, money.id
    assert_includes Slot.euro_compensation.ids, both.id
    assert_not_includes Slot.euro_compensation.ids, days.id

    assert_includes Slot.day_compensation.ids, days.id
    assert_includes Slot.day_compensation.ids, both.id
    assert_not_includes Slot.day_compensation.ids, money.id
  end

  test "invalid assignment_state is rejected" do
    slot = Slot.new(starts_at: Time.current, assignment_state: "bogus")
    assert_not slot.valid?
  end
end

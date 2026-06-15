require "test_helper"

class SlotWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Ad", last_name: "Min",
                          role: "admin", password: "password123", active: true)
    @collab = User.create!(email: "collab@example.com", first_name: "Col", last_name: "Lab",
                           role: "collaborateur", password: "password123", active: true)
  end

  def login(email, password = "password123")
    post "/login", params: { email: email, password: password }
  end

  def build_slot(attrs = {})
    Slot.create!({ starts_at: 2.days.from_now, ends_at: 2.days.from_now + 4.hours }.merge(attrs))
  end

  test "a manager creates an available slot" do
    login("admin@example.com")
    assert_difference -> { Slot.count }, 1 do
      post "/slots/create", params: { slot: {
        starts_at: 2.days.from_now.to_s, ends_at: (2.days.from_now + 4.hours).to_s,
        slot_type: "jour", compensation_money: 120
      } }
    end
    assert Slot.last.available?
  end

  test "a collaborateur cannot create a slot" do
    login("collab@example.com")
    assert_no_difference -> { Slot.count } do
      post "/slots/create", params: { slot: {
        starts_at: 1.day.from_now.to_s, ends_at: (1.day.from_now + 1.hour).to_s, slot_type: "jour"
      } }
    end
    assert_redirected_to "/slots"
  end

  test "taking a slot creates a pending request rather than assigning it" do
    slot = build_slot
    login("collab@example.com")

    post "/slots/#{slot.id}/take/#{@collab.id}"

    slot.reload
    assert slot.pending?
    assert_equal @collab.id, slot.requested_by_id
    assert_nil slot.user_id
  end

  test "a manager validates a pending request" do
    slot = build_slot(assignment_state: "pending", requested_by: @collab)
    login("admin@example.com")

    post "/slots/#{slot.id}/validate"

    slot.reload
    assert slot.assigned?
    assert_equal @collab.id, slot.user_id
    assert_nil slot.requested_by_id
  end

  test "a manager rejects a pending request and the slot becomes available" do
    slot = build_slot(assignment_state: "pending", requested_by: @collab)
    login("admin@example.com")

    post "/slots/#{slot.id}/reject"

    slot.reload
    assert slot.available?
    assert_nil slot.requested_by_id
  end

  test "releasing an assigned slot frees it" do
    slot = build_slot(assignment_state: "assigned", user: @collab)
    login("admin@example.com")

    post "/slots/#{slot.id}/unassign"

    slot.reload
    assert slot.available?
    assert_nil slot.user_id
  end

  test "a responsable only manages slots of their own service" do
    svc   = Service.create!(name: "Prod")
    other = Service.create!(name: "Support")
    resp  = User.create!(email: "resp@example.com", first_name: "Re", last_name: "Sp",
                         role: "responsable", service: svc, password: "password123", active: true)
    foreign_slot = build_slot(assignment_state: "pending", requested_by: @collab, service: other)

    login("resp@example.com")
    post "/slots/#{foreign_slot.id}/validate"

    assert_response :forbidden
    assert foreign_slot.reload.pending?
  end
end

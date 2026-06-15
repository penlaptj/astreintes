require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  def build_user(attrs = {})
    defaults = {
      email: "u#{SecureRandom.hex(4)}@example.com",
      first_name: "First",
      last_name: "Last",
      password: "password123",
      role: "collaborateur",
      active: true
    }
    User.create!(defaults.merge(attrs))
  end

  test "name is required and unique" do
    Service.create!(name: "Prod")
    assert_not Service.new(name: "").valid?
    assert_not Service.new(name: "Prod").valid?
    assert_not Service.new(name: "PROD").valid? # insensible à la casse
  end

  test "collaborators returns active collaborateurs of the service" do
    svc = Service.create!(name: "Prod")
    active   = build_user(role: "collaborateur", service: svc, active: true)
    inactive = build_user(role: "collaborateur", service: svc, active: false)
    resp     = build_user(role: "responsable", service: svc)

    ids = svc.collaborators.ids
    assert_includes ids, active.id
    assert_not_includes ids, inactive.id
    assert_not_includes ids, resp.id
  end

  test "managers includes the service responsable and all admins" do
    svc    = Service.create!(name: "Prod")
    resp   = build_user(role: "responsable", service: svc)
    admin  = build_user(role: "admin")
    collab = build_user(role: "collaborateur", service: svc)

    ids = svc.managers.ids
    assert_includes ids, resp.id
    assert_includes ids, admin.id
    assert_not_includes ids, collab.id
  end

  test "destroying a service nullifies its users and slots" do
    svc = Service.create!(name: "Prod")
    user = build_user(service: svc)
    slot = Slot.create!(starts_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours, service: svc)

    svc.destroy
    assert_nil user.reload.service_id
    assert_nil slot.reload.service_id
  end
end

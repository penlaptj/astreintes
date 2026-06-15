require "test_helper"

class UserTest < ActiveSupport::TestCase
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

  test "role predicates" do
    assert build_user(role: "admin").admin?
    assert build_user(role: "responsable").responsable?
    assert build_user(role: "collaborateur").collaborateur?
  end

  test "manager and global_manager scopes by role" do
    assert build_user(role: "admin").global_manager?
    assert build_user(role: "responsable").manager?
    assert_not build_user(role: "responsable").global_manager?
    assert_not build_user(role: "collaborateur").manager?
  end

  test "admin manages every user" do
    admin = build_user(role: "admin")
    build_user(role: "collaborateur")
    assert_equal User.count, admin.manageable_users.count
  end

  test "responsable manages only their service users" do
    svc   = Service.create!(name: "Prod")
    other = Service.create!(name: "Support")
    resp  = build_user(role: "responsable", service: svc)
    mine  = build_user(role: "collaborateur", service: svc)
    theirs = build_user(role: "collaborateur", service: other)

    ids = resp.manageable_users.ids
    assert_includes ids, mine.id
    assert_includes ids, resp.id
    assert_not_includes ids, theirs.id
  end

  test "responsable without a service manages nobody" do
    resp = build_user(role: "responsable")
    assert_equal 0, resp.manageable_users.count
  end

  test "manages_service? respects scope" do
    svc   = Service.create!(name: "Prod")
    other = Service.create!(name: "Support")
    admin = build_user(role: "admin")
    resp  = build_user(role: "responsable", service: svc)

    assert admin.manages_service?(svc)
    assert resp.manages_service?(svc)
    assert_not resp.manages_service?(other)
    assert_not resp.manages_service?(nil)
  end

  test "invitation token round-trips and invalidates after password change" do
    user  = build_user(active: false)
    token = user.generate_token_for(:invitation)
    assert_equal user, User.find_by_token_for(:invitation, token)

    user.update!(password: "a-brand-new-password")
    assert_nil User.find_by_token_for(:invitation, token)
  end
end

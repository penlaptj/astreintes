require "test_helper"

class InvitationFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @admin = User.create!(
      email: "admin@example.com", first_name: "Ad", last_name: "Min",
      role: "admin", password: "password123", active: true
    )
  end

  def login(email, password)
    post "/login", params: { email: email, password: password }
  end

  test "an admin invites a user who then activates their account" do
    login("admin@example.com", "password123")

    assert_enqueued_emails 1 do
      post "/users", params: {
        first_name: "New", last_name: "User",
        email: "new@example.com", role: "collaborateur"
      }
    end

    user = User.find_by(email: "new@example.com")
    assert_not_nil user
    assert_not user.active?, "l'invité doit être inactif tant qu'il n'a pas défini son mot de passe"

    token = user.generate_token_for(:invitation)

    get "/invitations/#{token}"
    assert_response :success

    patch "/invitations/#{token}", params: {
      password: "my-new-password", password_confirmation: "my-new-password"
    }
    assert_redirected_to "/slots"

    user.reload
    assert user.active?
    assert user.authenticate("my-new-password")
  end

  test "an invalid invitation token redirects to login" do
    get "/invitations/not-a-real-token"
    assert_redirected_to "/login"
  end

  test "a collaborateur cannot invite users" do
    User.create!(email: "c@example.com", first_name: "C", last_name: "L",
                 role: "collaborateur", password: "password123", active: true)
    login("c@example.com", "password123")

    assert_no_difference -> { User.count } do
      post "/users", params: { first_name: "X", last_name: "Y", email: "x@example.com", role: "collaborateur" }
    end
    assert_redirected_to "/slots"
  end
end

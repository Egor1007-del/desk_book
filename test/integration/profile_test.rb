require "test_helper"

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @position = Position.create!(name: "Developer")
    @other_position = Position.create!(name: "Manager")
    @employee = create_user(login: "employee", role: :employee, position: @position)
    @other_user = create_user(login: "other", role: :employee, position: @other_position)
    @admin = create_user(login: "admin", role: :admin, position: @other_position)
  end

  test "routes the singular profile through the web namespace" do
    edit_route = Rails.application.routes.recognize_path("/profile/edit", method: :get)
    update_route = Rails.application.routes.recognize_path("/profile", method: :patch)

    assert_equal "web/profiles", edit_route.fetch(:controller)
    assert_equal "edit", edit_route.fetch(:action)
    assert_equal "web/profiles", update_route.fetch(:controller)
    assert_equal "update", update_route.fetch(:action)
  end

  test "requires authentication for editing and updating a profile" do
    get edit_profile_path
    assert_redirected_to new_user_session_path

    patch profile_path, params: { user: { phone: "+7 900 000 00 00" } }
    assert_redirected_to new_user_session_path
  end

  test "employee and administrator can open their own profile" do
    sign_in_as(@employee)
    get edit_profile_path

    assert_response :success
    assert_select "h1", text: "Edit profile"
    assert_select "input[name='user[login]'][value='employee']"

    delete destroy_user_session_path
    sign_in_as(@admin)
    get edit_profile_path

    assert_response :success
    assert_select "input[name='user[login]'][value='admin']"
  end

  test "employee updates permitted fields without changing a blank password" do
    sign_in_as(@employee)
    encrypted_password = @employee.encrypted_password

    patch profile_path, params: {
      id: @other_user.id,
      user: {
        phone: "+7 900 111 22 33",
        email: "updated@example.com",
        login: " Updated.Login ",
        password: "",
        password_confirmation: "",
        first_name: "Hacked",
        position_id: @other_position.id,
        role_name: "admin"
      }
    }

    assert_redirected_to edit_profile_path
    @employee.reload
    assert_equal "+7 900 111 22 33", @employee.phone
    assert_equal "updated@example.com", @employee.email
    assert_equal "updated.login", @employee.login
    assert_equal encrypted_password, @employee.encrypted_password
    assert @employee.valid_password?("secret123")
    assert_equal "Employee", @employee.first_name
    assert_equal @position, @employee.position
    assert @employee.only_has_role?(:employee)
    assert_equal "Other", @other_user.reload.first_name
  end

  test "employee changes the profile password with confirmation" do
    sign_in_as(@employee)

    patch profile_path, params: {
      user: {
        phone: @employee.phone,
        email: @employee.email,
        login: @employee.login,
        password: "new-secret",
        password_confirmation: "new-secret"
      }
    }

    assert_redirected_to edit_profile_path
    assert @employee.reload.valid_password?("new-secret")
    assert_not @employee.valid_password?("secret123")

    follow_redirect!
    assert_response :success
    assert_select "input[name='user[login]'][value='employee']"
  end

  test "profile rejects a mismatched password confirmation" do
    sign_in_as(@employee)

    patch profile_path, params: {
      user: {
        phone: @employee.phone,
        email: @employee.email,
        login: @employee.login,
        password: "new-secret",
        password_confirmation: "different-secret"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", text: /doesn't match/
    assert @employee.reload.valid_password?("secret123")
  end

  test "administrator updates only permitted fields through the profile" do
    sign_in_as(@admin)

    patch profile_path, params: {
      user: {
        phone: "+7 900 444 55 66",
        login: "admin.updated",
        first_name: "Hacked",
        role_name: "employee"
      }
    }

    assert_redirected_to edit_profile_path
    @admin.reload
    assert_equal "+7 900 444 55 66", @admin.phone
    assert_equal "admin.updated", @admin.login
    assert_equal "Admin", @admin.first_name
    assert @admin.only_has_role?(:admin)
  end

  test "invalid profile update returns the form and does not persist changes" do
    sign_in_as(@employee)

    patch profile_path, params: {
      user: {
        phone: "+7 900 111 22 33",
        email: "invalid-email",
        login: "",
        password: "new-secret",
        password_confirmation: "different-secret"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback"
    @employee.reload
    assert_nil @employee.phone
    assert_equal "employee@example.com", @employee.email
    assert_equal "employee", @employee.login
    assert @employee.valid_password?("secret123")
  end

  private

  def create_user(login:, role:, position:)
    User.new(
      last_name: login.capitalize,
      first_name: login.capitalize,
      position: position,
      hired_on: Date.new(2024, 1, 15),
      email: "#{login}@example.com",
      login: login,
      password: "secret123",
      password_confirmation: "secret123"
    ).tap do |user|
      user.save_with_role!(role: role)
    end
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end
end

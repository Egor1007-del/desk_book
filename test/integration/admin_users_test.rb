require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  setup do
    @position = Position.create!(name: "Developer")
    @other_position = Position.create!(name: "Manager")
    @admin = create_user(login: "admin", role: :admin, position: @other_position)
    @employee = create_user(login: "employee", role: :employee, position: @position)
  end

  test "administrator can browse the separate management interface" do
    sign_in_as(@admin)

    get admin_users_path
    assert_response :success
    assert_select "h1", text: I18n.t("admin.users.index.title")
    assert_select "a[href='#{new_admin_user_path}']", text: I18n.t("admin.users.new.title")
    assert_select "td.text-nowrap .d-flex.flex-nowrap.gap-1", count: 2

    get admin_user_path(@employee)
    assert_response :success
    assert_select "h1", text: @employee.full_name
    assert_select "dd", text: @employee.login
  end

  test "new and edit forms can render inside the management frame" do
    sign_in_as(@admin)

    get new_admin_user_path, headers: { "Turbo-Frame" => "admin_user_form" }
    assert_response :success
    assert_select "turbo-frame#admin_user_form" do
      assert_select "form[action='#{admin_users_path}']"
      assert_select "button[data-action='admin-user-form#close']", text: I18n.t("actions.cancel")
    end

    get edit_admin_user_path(@employee), headers: { "Turbo-Frame" => "admin_user_form" }
    assert_response :success
    assert_select "turbo-frame#admin_user_form form[action='#{admin_user_path(@employee)}']"
  end

  test "direct edit stays a full page and redirects after a Turbo submission" do
    sign_in_as(@admin)

    get edit_admin_user_path(@employee)
    assert_response :success
    assert_select "h1", text: I18n.t("admin.users.edit.title", name: @employee.full_name)
    assert_select "turbo-frame#admin_user_form", count: 0
    assert_select "a[href='#{admin_user_path(@employee)}']", text: I18n.t("actions.cancel")

    patch admin_user_path(@employee), params: {
      user: update_params(last_name: "Direct")
    }, headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_redirected_to admin_user_path(@employee)
    assert_equal "Direct", @employee.reload.last_name
  end

  test "administrator creates an employee with a Turbo Stream response" do
    sign_in_as(@admin)

    assert_difference -> { User.count }, 1 do
      post admin_users_path, params: { user: new_user_params }, headers: turbo_stream_headers
    end

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_turbo_stream_targets "admin_users_table_body", "admin_users_count",
      "admin_user_form", "flash_messages"
    assert_includes response.body, I18n.t("flash.users.created")
  end

  test "invalid Turbo Stream creation returns the frame with errors" do
    sign_in_as(@admin)

    assert_no_difference -> { User.count } do
      post admin_users_path, params: { user: new_user_params.merge(last_name: "") },
        headers: turbo_stream_headers
    end

    assert_response :unprocessable_entity
    assert_equal "text/html", response.media_type
    assert_select "turbo-frame#admin_user_form .invalid-feedback"
  end

  test "administrator updates and deletes an employee with Turbo Stream responses" do
    sign_in_as(@admin)

    patch admin_user_path(@employee), params: {
      user: update_params(last_name: "Updated")
    }, headers: turbo_stream_headers
    assert_response :success
    assert_turbo_stream_targets "admin_users_table_body", "admin_users_count",
      "admin_user_form", "flash_messages"
    assert_equal "Updated", @employee.reload.last_name

    assert_difference -> { User.count }, -1 do
      delete admin_user_path(@employee), headers: turbo_stream_headers
    end
    assert_response :success
    assert_select "turbo-stream[action='remove'][target='user_#{@employee.id}']", count: 1
    assert_turbo_stream_targets "admin_users_count", "flash_messages"
  end

  test "employee cannot access administrative management" do
    sign_in_as(@employee)

    get admin_users_path

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert-danger", text: I18n.t("authorization.denied")
  end

  test "employee cannot update or delete another user" do
    sign_in_as(@employee)

    patch admin_user_path(@admin), params: {
      user: update_params(last_name: "Hacked", role_name: "employee")
    }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @admin.reload.last_name

    assert_no_difference -> { User.count } do
      delete admin_user_path(@admin)
    end
    assert_redirected_to root_path
  end

  test "administrator creates an employee with one role" do
    sign_in_as(@admin)

    assert_difference -> { User.count }, 1 do
      post admin_users_path, params: { user: new_user_params }
    end

    created_user = User.find_by!(login: "new.employee")
    assert_redirected_to admin_user_path(created_user)
    assert created_user.only_has_role?(:employee)
    assert created_user.valid_password?("secret123")
    assert_equal "+7 918 123 45 67", created_user.phone
  end

  test "invalid creation returns the form without persisting a user" do
    sign_in_as(@admin)
    attributes = new_user_params.merge(last_name: "")

    assert_no_difference -> { User.count } do
      post admin_users_path, params: { user: attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback"
  end

  test "creation rejects an invalid role and missing password confirmation" do
    sign_in_as(@admin)
    attributes = new_user_params.except(:password_confirmation).merge(role_name: "manager")

    assert_no_difference -> { User.count } do
      post admin_users_path, params: { user: attributes }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", minimum: 2
  end

  test "administrator updates an employee without changing a blank password" do
    sign_in_as(@admin)
    encrypted_password = @employee.encrypted_password

    patch admin_user_path(@employee), params: {
      user: update_params(last_name: "Updated", password: "", password_confirmation: "")
    }

    assert_redirected_to admin_user_path(@employee)
    @employee.reload
    assert_equal "Updated", @employee.last_name
    assert_equal encrypted_password, @employee.encrypted_password
    assert @employee.valid_password?("secret123")
  end

  test "administrator changes password and role atomically" do
    sign_in_as(@admin)

    patch admin_user_path(@employee), params: {
      user: update_params(
        role_name: "admin",
        password: "new-secret",
        password_confirmation: "new-secret"
      )
    }

    assert_redirected_to admin_user_path(@employee)
    assert @employee.reload.only_has_role?(:admin)
    assert @employee.valid_password?("new-secret")
  end

  test "invalid update returns the form and rolls back attributes and role" do
    sign_in_as(@admin)

    patch admin_user_path(@employee), params: {
      user: update_params(last_name: "", role_name: "admin", password: "", password_confirmation: "")
    }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback"
    assert_equal "Employee", @employee.reload.last_name
    assert @employee.only_has_role?(:employee)
  end

  test "administrator deletes an employee" do
    sign_in_as(@admin)

    assert_difference -> { User.count }, -1 do
      delete admin_user_path(@employee)
    end

    assert_redirected_to admin_users_path
  end

  test "last administrator cannot be deleted or demoted" do
    sign_in_as(@admin)

    assert_no_difference -> { User.count } do
      delete admin_user_path(@admin)
    end
    assert_redirected_to root_path

    patch admin_user_path(@admin), params: {
      user: update_params(role_name: "employee", password: "", password_confirmation: "")
    }
    assert_redirected_to root_path
    assert @admin.reload.only_has_role?(:admin)
  end

  test "administrator can demote self when another administrator remains" do
    create_user(login: "second.admin", role: :admin, position: @other_position)
    sign_in_as(@admin)

    patch admin_user_path(@admin), params: {
      user: update_params(@admin, role_name: "employee")
    }

    assert_redirected_to admin_user_path(@admin)
    assert @admin.reload.only_has_role?(:employee)
    get root_path
    assert_response :success
  end

  test "administrator can delete self when another administrator remains" do
    create_user(login: "second.admin", role: :admin, position: @other_position)
    sign_in_as(@admin)

    assert_difference -> { User.count }, -1 do
      delete admin_user_path(@admin)
    end

    assert_redirected_to admin_users_path
    follow_redirect!
    assert_redirected_to new_user_session_path
  end

  private

  def create_user(login:, role:, position:)
    User.new(
      last_name: login.capitalize,
      first_name: "User",
      position: position,
      hired_on: Date.new(2024, 1, 15),
      login: login,
      password: "secret123",
      password_confirmation: "secret123"
    ).tap do |user|
      user.save_with_role!(role: role)
    end
  end

  def new_user_params
    {
      last_name: "New",
      first_name: "Employee",
      middle_name: "Test",
      position_id: @position.id,
      hired_on: "2025-02-10",
      phone: "8 (918) 123-45-67",
      email: "new.employee@example.com",
      login: "new.employee",
      password: "secret123",
      password_confirmation: "secret123",
      role_name: "employee"
    }
  end

  def update_params(user = @employee, **overrides)
    {
      last_name: user.last_name,
      first_name: user.first_name,
      middle_name: user.middle_name,
      position_id: user.position_id,
      hired_on: user.hired_on.iso8601,
      phone: user.phone,
      email: user.email,
      login: user.login,
      role_name: user.role_name
    }.merge(overrides)
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end

  def turbo_stream_headers
    { "Accept" => Mime[:turbo_stream].to_s, "Turbo-Frame" => "admin_user_form" }
  end

  def assert_turbo_stream_targets(*targets)
    targets.each do |target|
      assert_select "turbo-stream[target='#{target}']", count: 1
    end
  end
end

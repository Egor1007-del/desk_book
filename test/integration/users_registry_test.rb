require "test_helper"

class UsersRegistryTest < ActionDispatch::IntegrationTest
  setup do
    @position = Position.create!(name: "Developer")
    @admin_position = Position.create!(name: "Manager")

    @employee = User.new(
      last_name: "Ivanov",
      first_name: "Ivan",
      middle_name: "Ivanovich",
      position: @position,
      hired_on: Date.new(2024, 3, 1),
      phone: "+7 900 123 45 67",
      email: "ivanov@example.com",
      login: "ivanov",
      password: "secret123",
      password_confirmation: "secret123"
    )
    @employee.save_with_role!(role: :employee)

    @admin = User.new(
      last_name: "Petrov",
      first_name: "Petr",
      position: @admin_position,
      hired_on: Date.new(2023, 1, 15),
      phone: "+7 900 765 43 21",
      email: "petrov@example.com",
      login: "petrov",
      password: "secret123",
      password_confirmation: "secret123"
    )
    @admin.save_with_role!(role: :admin)
  end

  test "employee sees registry with allowed fields only" do
    sign_in_as(@employee)

    get users_path

    assert_response :success
    assert_select "title", text: "Employee directory"
    assert_select "h1", text: "Employee directory"
    assert_select "th", text: "Full name"
    assert_select "th", text: "Position"
    assert_select "th", text: "Hired on"
    assert_select "th", text: "Phone"
    assert_select "th", text: "Email"
    assert_select "th", text: "Login", count: 0
    assert_select "th", text: "Role", count: 0
    assert_select "td", text: @employee.full_name
    assert_select "td", text: @admin.full_name
  end

  test "admin sees registry with login and role" do
    sign_in_as(@admin)

    get users_path

    assert_response :success
    assert_select "th", text: "Login"
    assert_select "th", text: "Role"
    assert_select "td", text: @employee.login
    assert_select "td", text: @admin.login
    assert_select "td", text: "Employee"
    assert_select "td", text: "Admin"
    assert_select "td.text-nowrap .d-flex.flex-nowrap.gap-1", count: 2
  end

  test "employee sees own card without login and role" do
    sign_in_as(@employee)

    get user_path(@employee)

    assert_response :success
    assert_select "title", text: @employee.full_name
    assert_select "h1", text: @employee.full_name
    assert_select "dt", text: "Phone"
    assert_select "dd", text: @employee.phone
    assert_select "dd", text: @employee.email
    assert_select "dt", text: "Login", count: 0
    assert_select "dt", text: "Role", count: 0
    assert_select "a[href='#{edit_admin_user_path(@employee)}']", count: 0
    assert_select "form[action='#{admin_user_path(@employee)}']", count: 0
  end

  test "admin sees any card with login and role" do
    sign_in_as(@admin)

    get user_path(@employee)

    assert_response :success
    assert_select "dt", text: "Login"
    assert_select "dd", text: @employee.login
    assert_select "dt", text: "Role"
    assert_select "dd", text: "Employee"
    assert_select "a[href='#{edit_admin_user_path(@employee)}']", text: "Edit"
  end

  test "employee cannot access admin edit" do
    sign_in_as(@employee)

    get edit_admin_user_path(@employee)

    assert_response :redirect
    follow_redirect!
    assert_select ".alert-danger", text: /not authorized/
  end

  test "admin can access admin edit" do
    sign_in_as(@admin)

    get edit_admin_user_path(@employee)

    assert_response :success
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end
end

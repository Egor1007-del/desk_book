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
    assert_select "title", text: I18n.t("users.index.title")
    assert_select "h1", text: I18n.t("users.index.title")
    assert_select "th", text: I18n.t("attributes.full_name")
    assert_select "th", text: User.human_attribute_name(:position)
    assert_select "th", text: User.human_attribute_name(:hired_on)
    assert_select "th", text: User.human_attribute_name(:phone)
    assert_select "th", text: User.human_attribute_name(:email)
    assert_select "th", text: User.human_attribute_name(:login), count: 0
    assert_select "th", text: User.human_attribute_name(:role_name), count: 0
    assert_select "td", text: @employee.full_name
    assert_select "td", text: @admin.full_name
  end

  test "admin sees registry with login and role" do
    sign_in_as(@admin)

    get users_path

    assert_redirected_to admin_users_path
    follow_redirect!
    assert_response :success
    assert_select "th", text: User.human_attribute_name(:login)
    assert_select "th", text: User.human_attribute_name(:role_name)
    assert_select "td", text: @employee.login
    assert_select "td", text: @admin.login
    assert_select "td", text: I18n.t("roles.employee")
    assert_select "td", text: I18n.t("roles.admin")
    assert_select "td.text-nowrap .d-flex.flex-nowrap.gap-1", count: 2
  end

  test "employee sees another user's card without login and role" do
    sign_in_as(@employee)

    get user_path(@admin)

    assert_response :success
    assert_select "title", text: @admin.full_name
    assert_select "h1", text: @admin.full_name
    assert_select "dt", text: User.human_attribute_name(:phone)
    assert_select "dd", text: @admin.phone
    assert_select "dd", text: @admin.email
    assert_select "dt", text: User.human_attribute_name(:login), count: 0
    assert_select "dt", text: User.human_attribute_name(:role_name), count: 0
    assert_select "a[href='#{edit_admin_user_path(@admin)}']", count: 0
    assert_select "form[action='#{admin_user_path(@admin)}']", count: 0
  end

  test "admin sees any card with login and role" do
    sign_in_as(@admin)

    get user_path(@employee)

    assert_redirected_to admin_user_path(@employee)
    follow_redirect!
    assert_response :success
    assert_select "dt", text: User.human_attribute_name(:login)
    assert_select "dd", text: @employee.login
    assert_select "dt", text: User.human_attribute_name(:role_name)
    assert_select "dd", text: I18n.t("roles.employee")
    assert_select "a[href='#{edit_admin_user_path(@employee)}']", text: I18n.t("actions.edit")
  end

  test "employee cannot access admin edit" do
    sign_in_as(@employee)

    get edit_admin_user_path(@employee)

    assert_response :redirect
    follow_redirect!
    assert_select ".alert-danger", text: I18n.t("authorization.denied")
  end

  test "admin can access admin edit" do
    sign_in_as(@admin)

    get edit_admin_user_path(@employee)

    assert_response :success
  end

  test "employee home links to the public directory" do
    sign_in_as(@employee)

    assert_select "a[href='#{users_path}']", text: I18n.t("users.index.open")
    assert_select "a[href='#{admin_users_path}']", count: 0
  end

  test "admin home links to management" do
    sign_in_as(@admin)

    assert_select "a[href='#{admin_users_path}']", text: I18n.t("admin.users.index.title")
    assert_select "a[href='#{users_path}']", count: 0
  end

  test "management shows contact details and registry links" do
    sign_in_as(@admin)
    get admin_users_path

    assert_response :success
    assert_select "th", text: User.human_attribute_name(:phone)
    assert_select "th", text: User.human_attribute_name(:email)
    assert_select "th", text: User.human_attribute_name(:hired_on)
    assert_select "td", text: @employee.phone
    assert_select "td", text: @employee.email
    assert_select "td", text: I18n.l(@employee.hired_on, format: :short)
    assert_select "a[href='#{edit_profile_path}']", text: I18n.t("profiles.edit.title")
    assert_select "a[href='#{users_path(format: :xlsx)}'][data-turbo='false']", text: I18n.t("actions.download_excel")
    assert_select "a[href='#{users_path}']", count: 0
  end

  test "admin card does not link to the public card" do
    sign_in_as(@admin)
    get admin_user_path(@employee)

    assert_response :success
    assert_select "a[href='#{user_path(@employee)}']", count: 0
  end

  test "employee directory shows the total number of employees" do
    sign_in_as(@employee)
    get users_path

    assert_response :success
    assert_select "p", text: I18n.t("employees.count", count: 2)
  end

  test "management shows the total number of employees" do
    sign_in_as(@admin)
    get admin_users_path

    assert_response :success
    assert_select "p", text: I18n.t("employees.count", count: 2)
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end
end

require "test_helper"

class AdminAnalyticsTest < ActionDispatch::IntegrationTest
  setup do
    @empty_position = Position.create!(name: "Designer")
    @developer_position = Position.create!(name: "Developer")
    @manager_position = Position.create!(name: "Manager")
    @admin = create_user(login: "admin", position: @manager_position, role: :admin)
    @employee = create_user(login: "employee", position: @developer_position)
  end

  test "anonymous visitor must sign in" do
    get admin_analytics_path

    assert_redirected_to new_user_session_path
  end

  test "employee cannot access analytics" do
    sign_in_as(@employee)

    get admin_analytics_path

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".alert-danger", text: I18n.t("authorization.denied")
  end

  test "administrator sees all positions in alphabetical order" do
    sign_in_as(@admin)

    get admin_analytics_path

    assert_response :success
    assert_select "title", text: I18n.t("admin.analytics.title")
    assert_select "h1", text: I18n.t("admin.analytics.title")
    assert_select "section h2" do |headings|
      assert_equal Position.order(:name).pluck(:name), headings.map(&:text)
    end
  end

  test "empty position shows zero employees" do
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "#position_#{@empty_position.id}" do
      assert_select ".badge", text: I18n.t("admin.analytics.total", count: 0)
      assert_select "p", text: I18n.t("admin.analytics.no_employees")
      assert_select "tbody tr", count: 0
    end
  end

  test "employee details appear only under their position" do
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "#position_#{@developer_position.id}" do
      assert_select ".badge", text: I18n.t("admin.analytics.total", count: 1)
      assert_select "tbody tr", count: 1
      assert_select "a[href='#{admin_user_path(@employee)}']", text: @employee.full_name
      assert_select "td", text: I18n.l(@employee.hired_on, format: :short)
      assert_select "a[href='#{admin_user_path(@admin)}']", count: 0
    end
    assert_select "#position_#{@manager_position.id}" do
      assert_select ".badge", text: I18n.t("admin.analytics.total", count: 1)
      assert_select "a[href='#{admin_user_path(@admin)}']", text: @admin.full_name
      assert_select "a[href='#{admin_user_path(@employee)}']", count: 0
    end
  end

  test "position shows five latest employees but counts all six" do
    5.times do |number|
      create_user(
        login: "new-developer-#{number}", position: @developer_position,
        hired_on: Date.new(2025, 1, 1)
      )
    end
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "#position_#{@developer_position.id}" do
      assert_select ".badge", text: I18n.t("admin.analytics.total", count: 6)
      assert_select "tbody tr", count: 5
      assert_select "a[href='#{admin_user_path(@employee)}']", count: 0
    end
    assert_select "#position_#{@manager_position.id} tbody tr", count: 1
  end

  test "employees are ordered by hire date rather than creation order" do
    newer_employee = create_user(
      login: "newer", position: @developer_position, hired_on: Date.new(2025, 6, 1)
    )
    older_employee = create_user(
      login: "older", position: @developer_position, hired_on: Date.new(2025, 1, 1)
    )
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "#position_#{@developer_position.id} tbody a" do |links|
      assert_equal [ newer_employee.full_name, older_employee.full_name, @employee.full_name ], links.map(&:text)
    end
  end

  test "higher id comes first when hire dates are equal" do
    first_employee = create_user(
      login: "first", position: @empty_position, hired_on: Date.new(2025, 1, 1)
    )
    second_employee = create_user(
      login: "second", position: @empty_position, hired_on: Date.new(2025, 1, 1)
    )
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "#position_#{@empty_position.id} tbody a" do |links|
      assert_equal [ second_employee.full_name, first_employee.full_name ], links.map(&:text)
    end
  end

  test "management page links to analytics" do
    sign_in_as(@admin)

    get admin_users_path

    assert_select "a[href='#{admin_analytics_path}']", text: I18n.t("admin.analytics.title")
  end

  test "analytics links back to management" do
    sign_in_as(@admin)
    get admin_analytics_path

    assert_select "a[href='#{admin_users_path}']", text: I18n.t("admin.users.index.title")
  end

  private

  def create_user(login:, position:, role: :employee, hired_on: Date.new(2024, 1, 15))
    User.new(
      last_name: login.capitalize, first_name: "Test", position: position,
      hired_on: hired_on, login: login,
      password: "secret123", password_confirmation: "secret123"
    ).tap { |user| user.save_with_role!(role: role) }
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end
end

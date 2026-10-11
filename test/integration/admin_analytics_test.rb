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
    assert_select ".alert-danger", text: "You are not authorized to perform this action."
  end

  test "administrator sees all positions including empty ones and total counts" do
    sign_in_as(@admin)

    get admin_analytics_path

    assert_response :success
    assert_select "title", text: "Employee analytics"
    assert_select "h1", text: "Employee analytics"
    assert_select "section h2" do |headings|
      assert_equal Position.order(:name).pluck(:name), headings.map(&:text)
    end
    assert_select "#position_#{@empty_position.id}" do
      assert_select ".badge", text: "Total employees: 0"
      assert_select "p", text: "No employees in this position."
      assert_select "tbody tr", count: 0
    end
    [ @employee, @admin ].each do |employee|
      assert_select "#position_#{employee.position_id}" do
        assert_select ".badge", text: "Total employees: 1"
        assert_select "tbody tr", count: 1
        assert_select "a[href='#{user_path(employee)}']", text: employee.full_name
        assert_select "td", text: I18n.l(employee.hired_on, format: :short)
      end
    end
  end

  test "latest five are ordered by hire date and then descending id for each position" do
    expected_by_position = [ @developer_position, @manager_position ].to_h do |position|
      hires = [ 6, 2, 5, 1, 6, 4, 3 ].each_with_index.map do |month, index|
        create_user(
          login: "hire-#{position.id}-#{index}", position: position,
          hired_on: Date.new(2025, month, 1)
        )
      end
      [ position, [ hires[4], hires[0], hires[2], hires[5], hires[6] ] ]
    end
    sign_in_as(@admin)

    get admin_analytics_path

    assert_response :success
    expected_by_position.each do |position, employees|
      assert_select "#position_#{position.id}" do
        assert_select ".badge", text: "Total employees: 8"
        assert_select "tbody tr", count: 5
        assert_select "tbody a" do |links|
          assert_equal employees.map(&:full_name), links.map(&:text)
          assert_equal employees.map { |employee| user_path(employee) }, links.map { |link| link["href"] }
        end
      end
    end
  end

  test "management page links to analytics and analytics links back" do
    sign_in_as(@admin)

    get admin_users_path

    assert_select "a[href='#{admin_analytics_path}']", text: "Analytics"

    get admin_analytics_path

    assert_select "a[href='#{admin_users_path}']", text: "Manage employees"
  end

  test "analytics uses stored totals without counting users" do
    sign_in_as(@admin)
    queries = []
    subscriber = ->(event) { queries << event.payload[:sql] }

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get admin_analytics_path
    end

    assert_response :success
    assert_empty queries.grep(/\bCOUNT\s*\(/i)
    assert_select "#position_#{@developer_position.id} .badge", text: "Total employees: 1"
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

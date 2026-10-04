require "test_helper"

class PolicyTestCase < ActiveSupport::TestCase
  private

  def create_user(login:, role:)
    position = Position.find_or_create_by!(name: "Developer")

    User.create_with_role!(
      {
        last_name: login.capitalize,
        first_name: "User",
        position: position,
        hired_on: Date.new(2024, 1, 15),
        login: login,
        password: "secret123",
        password_confirmation: "secret123"
      },
      role: role
    )
  end
end

class ApplicationPolicyTest < PolicyTestCase
  test "requires an authenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      ApplicationPolicy.new(nil, Object.new)
    end

    assert_raises(Pundit::NotAuthorizedError) do
      ApplicationPolicy::Scope.new(nil, User)
    end
  end

  test "denies actions by default" do
    user = create_user(login: "employee", role: :employee)
    policy = ApplicationPolicy.new(user, Object.new)

    %i[index? show? create? new? update? edit? destroy?].each do |query|
      assert_not policy.public_send(query)
    end

    assert_empty policy.permitted_attributes
  end

  test "requires web actions to authorize a record" do
    after_actions = Web::ApplicationController
      ._process_action_callbacks
      .select { |callback| callback.kind == :after }
      .map(&:filter)

    assert_includes after_actions, :verify_authorized
  end
end

class HomePolicyTest < PolicyTestCase
  test "allows authenticated users" do
    employee = create_user(login: "employee", role: :employee)
    admin = create_user(login: "admin", role: :admin)

    assert HomePolicy.new(employee, :home).show?
    assert HomePolicy.new(admin, :home).show?
  end
end

class UserPolicyTest < PolicyTestCase
  setup do
    @employee = create_user(login: "employee", role: :employee)
    @admin = create_user(login: "admin", role: :admin)
  end

  test "allows authenticated users to view and export the directory" do
    [ @employee, @admin ].each do |user|
      policy = UserPolicy.new(user, @employee)

      assert policy.index?
      assert policy.show?
      assert policy.export?
    end
  end

  test "shows login and role only to administrators" do
    employee_policy = UserPolicy.new(@employee, @admin)
    admin_policy = UserPolicy.new(@admin, @employee)

    assert_not employee_policy.show_login?
    assert_not employee_policy.show_role?
    assert admin_policy.show_login?
    assert admin_policy.show_role?
  end

  test "never allows password fields to be displayed" do
    [ @employee, @admin ].each do |user|
      policy = UserPolicy.new(user, @employee)

      assert_not policy.show_password?
      assert_not policy.show_encrypted_password?
    end
  end

  test "scope includes all users" do
    assert_equal User.order(:id).to_a, UserPolicy::Scope.new(@employee, User).resolve.order(:id).to_a
  end
end

class AdminUserPolicyTest < PolicyTestCase
  setup do
    @employee = create_user(login: "employee", role: :employee)
    @admin = create_user(login: "admin", role: :admin)
  end

  test "allows administrators to manage employees" do
    policy = Admin::UserPolicy.new(@admin, @employee)

    %i[index? show? create? new? update? edit? destroy? change_role?].each do |query|
      assert policy.public_send(query)
    end
  end

  test "denies administrative actions to employees" do
    policy = Admin::UserPolicy.new(@employee, @admin)

    %i[index? show? create? new? update? edit? destroy? change_role?].each do |query|
      assert_not policy.public_send(query)
    end
  end

  test "protects the last administrator from deletion and demotion" do
    policy = Admin::UserPolicy.new(@admin, @admin)

    assert policy.update?
    assert_not policy.destroy?
    assert_not policy.change_role?
  end

  test "allows removing an administrator when another administrator remains" do
    create_user(login: "second-admin", role: :admin)
    policy = Admin::UserPolicy.new(@admin, @admin)

    assert policy.destroy?
    assert policy.change_role?
  end

  test "allows only safe user attributes" do
    admin_attributes = Admin::UserPolicy.new(@admin, @employee).permitted_attributes

    assert_includes admin_attributes, :login
    assert_includes admin_attributes, :password
    assert_not_includes admin_attributes, :role
    assert_not_includes admin_attributes, :encrypted_password
    assert_empty Admin::UserPolicy.new(@employee, @employee).permitted_attributes
  end

  test "resolves users only for administrators" do
    assert_equal User.order(:id).to_a, Admin::UserPolicy::Scope.new(@admin, User).resolve.order(:id).to_a
    assert_empty Admin::UserPolicy::Scope.new(@employee, User).resolve
  end

  test "Pundit resolves the namespaced policy" do
    assert_instance_of Admin::UserPolicy, Pundit.policy!(@admin, [ :admin, @employee ])
  end
end

class ProfilePolicyTest < PolicyTestCase
  setup do
    @employee = create_user(login: "employee", role: :employee)
    @other_employee = create_user(login: "other-employee", role: :employee)
  end

  test "allows users to edit only their own profile" do
    own_policy = ProfilePolicy.new(@employee, @employee)
    other_policy = ProfilePolicy.new(@employee, @other_employee)

    assert own_policy.edit?
    assert own_policy.update?
    assert_not other_policy.edit?
    assert_not other_policy.update?
  end

  test "allows only profile attributes" do
    policy = ProfilePolicy.new(@employee, @employee)

    assert_equal %i[phone email login password password_confirmation], policy.permitted_attributes
    assert_not_includes policy.permitted_attributes, :role
    assert_not_includes policy.permitted_attributes, :encrypted_password
  end
end

class AdminAnalyticsPolicyTest < PolicyTestCase
  test "allows only administrators" do
    employee = create_user(login: "employee", role: :employee)
    admin = create_user(login: "admin", role: :admin)

    assert Admin::AnalyticsPolicy.new(admin, :analytics).show?
    assert_not Admin::AnalyticsPolicy.new(employee, :analytics).show?
  end
end

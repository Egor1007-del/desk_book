require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  setup do
    @position = Position.create!(name: "Developer")
  end

  test "creates a user with exactly one role" do
    user = create_user(role: :employee)

    assert_predicate user, :persisted?
    assert user.only_has_role?(:employee)
    assert_equal [ "employee" ], user.roles.pluck(:name)
  end

  test "rolls back user creation when the role is invalid" do
    assert_no_difference -> { User.count } do
      assert_raises(ArgumentError) do
        User.create_with_role!(user_attributes, role: :manager)
      end
    end
  end

  test "database prevents assigning a second role" do
    user = create_user(role: :employee)
    admin_role = Role.create!(name: "admin")

    assert_raises(ActiveRecord::RecordNotUnique) do
      user.roles << admin_role
    end

    assert user.reload.only_has_role?(:employee)
  end

  test "changes a role without retaining the previous role" do
    user = create_user(role: :employee)

    user.assign_role!(:admin)

    assert user.only_has_role?(:admin)
    assert_equal [ "admin" ], user.roles.reload.pluck(:name)
  end

  test "updates user attributes and role atomically" do
    user = create_user(role: :employee)

    user.update_with_role!({ last_name: "Smith" }, role: :admin)

    assert_equal "Smith", user.reload.last_name
    assert user.only_has_role?(:admin)
  end

  test "rolls back user attributes when changing the role fails" do
    user = create_user(role: :employee)

    assert_raises(ArgumentError) do
      user.update_with_role!({ last_name: "Smith" }, role: :manager)
    end

    assert_equal "Doe", user.reload.last_name
    assert user.only_has_role?(:employee)
  end

  test "provides the reverse association from role to users" do
    user = create_user(role: :admin)
    role = Role.find_by!(name: "admin")

    assert_includes role.users, user
  end

  private

  def create_user(role:)
    User.create_with_role!(user_attributes, role: role)
  end

  def user_attributes
    {
      last_name: "Doe",
      first_name: "John",
      position: @position,
      hired_on: Date.new(2024, 1, 15),
      login: "john.doe",
      password: "secret123",
      password_confirmation: "secret123"
    }
  end
end

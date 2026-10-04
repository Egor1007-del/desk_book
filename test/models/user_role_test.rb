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
      error = assert_raises(ActiveRecord::RecordInvalid) do
        User.new(user_attributes).save_with_role!(role: :manager)
      end

      assert_includes error.record.errors[:role_name], "is not included in the list"
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

    user.save_with_role!(role: :admin)

    assert user.only_has_role?(:admin)
    assert_equal [ "admin" ], user.roles.reload.pluck(:name)
  end

  test "updates user attributes and role atomically" do
    user = create_user(role: :employee)

    user.save_with_role!({ last_name: "Smith" }, role: :admin)

    assert_equal "Smith", user.reload.last_name
    assert user.only_has_role?(:admin)
  end

  test "rolls back user attributes when changing the role fails" do
    user = create_user(role: :employee)

    assert_raises(ActiveRecord::RecordInvalid) do
      user.save_with_role!({ last_name: "Smith" }, role: :manager)
    end

    assert_equal "Doe", user.reload.last_name
    assert user.only_has_role?(:employee)
  end

  test "prevents direct demotion of the last administrator" do
    admin = create_user(role: :admin)

    assert_raises(ActiveRecord::RecordInvalid) do
      admin.save_with_role!(role: :employee)
    end

    assert admin.reload.only_has_role?(:admin)
  end

  test "prevents demoting the last administrator" do
    admin = create_user(role: :admin)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      admin.save_with_role!({ last_name: "Smith" }, role: :employee)
    end

    assert_includes error.record.errors[:role_name], "cannot remove the last administrator"
    assert_equal "Doe", admin.reload.last_name
    assert admin.only_has_role?(:admin)
  end

  test "prevents destroying the last administrator" do
    admin = create_user(role: :admin)

    assert_raises(ActiveRecord::RecordInvalid) do
      admin.destroy_with_role_safety!
    end

    assert_predicate admin.reload, :persisted?
    assert admin.only_has_role?(:admin)
  end

  test "allows removing an administrator when another remains" do
    admin = create_user(role: :admin)
    User.new(user_attributes.merge(login: "second-admin")).save_with_role!(role: :admin)

    admin.destroy_with_role_safety!

    assert_predicate admin, :destroyed?
    assert_equal 1, User.with_role(:admin).count
  end

  test "provides the reverse association from role to users" do
    user = create_user(role: :admin)
    role = Role.find_by!(name: "admin")

    assert_includes role.users, user
  end

  private

  def create_user(role:)
    User.new(user_attributes).tap { |user| user.save_with_role!(role: role) }
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

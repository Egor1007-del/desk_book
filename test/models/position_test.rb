require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "requires a name" do
    position = Position.new

    assert_not position.valid?
    assert position.errors.of_kind?(:name, :blank)
  end

  test "requires a unique name" do
    Position.create!(name: "Developer")
    duplicate = Position.new(name: "Developer")

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end

  test "database index enforces unique names" do
    Position.create!(name: "Developer")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Position.insert!({ name: "Developer" })
    end
  end

  test "uses inverse associations" do
    position = Position.new(name: "Developer")
    user = position.users.build

    assert_same position, user.position
    assert_equal :position, Position.reflect_on_association(:users).inverse_of.name
    assert_equal :users, User.reflect_on_association(:position).inverse_of.name
  end

  test "does not destroy a position assigned to a user" do
    position = Position.create!(name: "Developer")
    position.users.create!(
      last_name: "Doe",
      first_name: "John",
      hired_on: Date.new(2024, 1, 15),
      login: "john.doe",
      encrypted_password: "password-digest"
    )

    assert_not position.destroy
    assert position.errors.of_kind?(:base, :"restrict_dependent_destroy.has_many")
    assert Position.exists?(position.id)
  end
end

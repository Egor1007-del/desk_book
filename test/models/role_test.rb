require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "allows only configured role names" do
    Role::NAMES.each do |name|
      assert Role.new(name: name).valid?
    end

    role = Role.new(name: "manager")

    assert_not role.valid?
    assert role.errors.of_kind?(:name, :inclusion)
  end

  test "requires role names to be unique" do
    Role.create!(name: "admin")
    duplicate = Role.new(name: "admin")

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end

  test "database index enforces unique role names" do
    Role.create!(name: "admin")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Role.insert!({ name: "admin" })
    end
  end

  test "does not allow resource scoped roles" do
    role = Role.new(name: "admin", resource: Position.new(name: "Developer"))

    assert_not role.valid?
    assert role.errors.of_kind?(:resource_type, :present)
  end
end

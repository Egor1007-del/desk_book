require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  setup do
    @original_admin_login = ENV["ADMIN_LOGIN"]
    @original_admin_password = ENV["ADMIN_PASSWORD"]
  end

  teardown do
    restore_env("ADMIN_LOGIN", @original_admin_login)
    restore_env("ADMIN_PASSWORD", @original_admin_password)
  end

  test "supports the educational default administrator credentials" do
    ENV.delete("ADMIN_LOGIN")
    ENV.delete("ADMIN_PASSWORD")

    load Rails.root.join("db/seeds.rb")

    admin = User.find_by!(login: "admin")

    assert admin.valid_password?("admin")
    assert admin.only_has_role?(:admin)
  end

  test "creates positions, roles, and an administrator" do
    seed!(login: "  ROOT  ", password: "secret123")

    assert_equal [ "должность 1", "должность 2", "должность 3" ], Position.order(:name).pluck(:name)
    assert_equal Role::NAMES.sort, Role.order(:name).pluck(:name)

    admin = User.find_by!(login: "root")

    assert_equal "Администратор", admin.last_name
    assert_equal "Системы", admin.first_name
    assert_nil admin.middle_name
    assert_equal "должность 1", admin.position.name
    assert_equal Date.current, admin.hired_on
    assert admin.only_has_role?(:admin)
    assert admin.valid_password?("secret123")
    assert_not_equal "secret123", admin.encrypted_password
  end

  test "is idempotent and does not replace an existing password or hiring date" do
    seed!(login: "admin", password: "original-password")
    admin = User.find_by!(login: "admin")
    original_attributes = admin.attributes.slice("id", "encrypted_password", "hired_on")

    seed!(login: "ADMIN", password: "replacement-password")

    admin.reload

    assert_equal 3, Position.count
    assert_equal 2, Role.count
    assert_equal 1, User.count
    assert_equal original_attributes, admin.attributes.slice("id", "encrypted_password", "hired_on")
    assert admin.valid_password?("original-password")
    assert_not admin.valid_password?("replacement-password")
    assert admin.only_has_role?(:admin)
  end

  test "restores the administrator role without changing the password" do
    seed!(login: "admin", password: "original-password")
    admin = User.find_by!(login: "admin")
    original_password = admin.encrypted_password
    admin.roles.clear

    seed!(login: "admin", password: "replacement-password")

    assert admin.reload.only_has_role?(:admin)
    assert_equal original_password, admin.encrypted_password
  end

  private

  def seed!(login:, password:)
    ENV["ADMIN_LOGIN"] = login
    ENV["ADMIN_PASSWORD"] = password
    load Rails.root.join("db/seeds.rb")
  end

  def restore_env(name, value)
    value.nil? ? ENV.delete(name) : ENV[name] = value
  end
end

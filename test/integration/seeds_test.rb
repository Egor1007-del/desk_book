require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  setup do
    @original_admin_login = ENV["ADMIN_LOGIN"]
    @original_admin_password = ENV["ADMIN_PASSWORD"]
    @original_employee_password = ENV["EMPLOYEE_PASSWORD"]
  end

  teardown do
    restore_env("ADMIN_LOGIN", @original_admin_login)
    restore_env("ADMIN_PASSWORD", @original_admin_password)
    restore_env("EMPLOYEE_PASSWORD", @original_employee_password)
  end

  test "supports the educational default administrator credentials" do
    ENV.delete("ADMIN_LOGIN")
    ENV.delete("ADMIN_PASSWORD")
    ENV.delete("EMPLOYEE_PASSWORD")

    load Rails.root.join("db/seeds.rb")

    admin = User.find_by!(login: "admin")
    employee = User.find_by!(login: "employee01")

    assert admin.valid_password?("admin")
    assert admin.only_has_role?(:admin)
    assert employee.valid_password?("employee")
    assert employee.only_has_role?(:employee)
  end

  test "creates positions, roles, an administrator, and thirty employees" do
    seed!(login: "  ROOT  ", password: "secret123", employee_password: "staff-secret")

    assert_equal [ "должность 1", "должность 2", "должность 3" ], Position.order(:name).pluck(:name)
    assert_equal Role::NAMES.sort, Role.order(:name).pluck(:name)
    assert_equal 31, User.count
    assert_equal 30, User.with_role(:employee).count
    assert_equal [ 10, 10, 10 ], Position.order(:name).map { |position| position.users.with_role(:employee).count }

    admin = User.find_by!(login: "root")

    assert_equal "Администратор", admin.last_name
    assert_equal "Системы", admin.first_name
    assert_nil admin.middle_name
    assert_equal "должность 1", admin.position.name
    assert_equal Date.current, admin.hired_on
    assert admin.only_has_role?(:admin)
    assert admin.valid_password?("secret123")
    assert_not_equal "secret123", admin.encrypted_password

    employee = User.find_by!(login: "employee02")

    assert_equal "Петрова", employee.last_name
    assert_equal "Анна", employee.first_name
    assert_equal "Викторовна", employee.middle_name
    assert_equal "должность 2", employee.position.name
    assert_equal Date.new(2019, 2, 2), employee.hired_on
    assert_equal "+7 900 000 00 02", employee.phone
    assert_equal "employee02@example.com", employee.email
    assert employee.only_has_role?(:employee)
    assert employee.valid_password?("staff-secret")

    employee_with_optional_fields = User.find_by!(login: "employee01")
    assert_nil employee_with_optional_fields.middle_name
    assert_nil employee_with_optional_fields.phone
    assert_nil employee_with_optional_fields.email
  end

  test "is idempotent and does not replace existing users" do
    seed!(login: "admin", password: "original-password", employee_password: "original-employee-password")
    admin = User.find_by!(login: "admin")
    original_admin_attributes = admin.attributes.slice("id", "encrypted_password", "hired_on")
    employee = User.find_by!(login: "employee02")
    employee.save_with_role!({ first_name: "Изменено" }, role: :admin)
    original_employee_attributes = employee.attributes.slice("id", "first_name", "encrypted_password", "hired_on")

    seed!(login: "ADMIN", password: "replacement-password", employee_password: "replacement-employee-password")

    admin.reload
    employee.reload

    assert_equal 3, Position.count
    assert_equal 2, Role.count
    assert_equal 31, User.count
    assert_equal original_admin_attributes, admin.attributes.slice("id", "encrypted_password", "hired_on")
    assert admin.valid_password?("original-password")
    assert_not admin.valid_password?("replacement-password")
    assert admin.only_has_role?(:admin)
    assert_equal original_employee_attributes,
      employee.attributes.slice("id", "first_name", "encrypted_password", "hired_on")
    assert employee.valid_password?("original-employee-password")
    assert_not employee.valid_password?("replacement-employee-password")
    assert employee.only_has_role?(:admin)
  end

  test "restores the administrator role without changing the password" do
    seed!(login: "admin", password: "original-password", employee_password: "staff-secret")
    admin = User.find_by!(login: "admin")
    original_password = admin.encrypted_password
    admin.roles.clear

    seed!(login: "admin", password: "replacement-password", employee_password: "replacement-employee-password")

    assert admin.reload.only_has_role?(:admin)
    assert_equal original_password, admin.encrypted_password
  end

  private

  def seed!(login:, password:, employee_password:)
    ENV["ADMIN_LOGIN"] = login
    ENV["ADMIN_PASSWORD"] = password
    ENV["EMPLOYEE_PASSWORD"] = employee_password
    load Rails.root.join("db/seeds.rb")
  end

  def restore_env(name, value)
    value.nil? ? ENV.delete(name) : ENV[name] = value
  end
end

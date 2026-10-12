require "application_system_test_case"

class AdminUserManagementTest < ApplicationSystemTestCase
  setup do
    @position = Position.create!(name: "Developer")
    admin_position = Position.create!(name: "Manager")
    @admin = create_user(login: "admin", role: :admin, position: admin_position)
  end

  test "administrator creates, edits, and deletes an employee" do
    sign_in_through_ui(@admin)
    click_link I18n.t("admin.users.index.title")
    click_link I18n.t("admin.users.new.title")

    fill_in "user_last_name", with: "New"
    fill_in "user_first_name", with: "Employee"
    fill_in "user_middle_name", with: "Test"
    select @position.name, from: "user_position_id"
    fill_in "user_hired_on", with: "2025-02-10"
    fill_in "user_phone", with: "8 (918) 123-45-67"
    fill_in "user_email", with: "new.employee@example.com"
    fill_in "user_login", with: "new.employee"
    fill_in "user_password", with: "secret123"
    fill_in "user_password_confirmation", with: "secret123"
    select I18n.t("roles.employee"), from: "user_role_name"
    click_button I18n.t("actions.save")

    assert_text I18n.t("flash.users.created")
    assert_selector "h1", text: "New Employee Test"
    click_link I18n.t("actions.edit")
    fill_in "user_last_name", with: "Updated"
    click_button I18n.t("actions.save")

    assert_text I18n.t("flash.users.updated")
    assert_selector "h1", text: "Updated Employee Test"
    click_link I18n.t("actions.back_to_management")

    within("tr", text: "Updated Employee Test") do
      dismiss_confirm do
        click_button I18n.t("actions.delete")
      end
    end
    assert_selector "tr", text: "Updated Employee Test"

    within("tr", text: "Updated Employee Test") do
      accept_confirm do
        click_button I18n.t("actions.delete")
      end
    end
    assert_text I18n.t("flash.users.deleted")
    assert_no_selector "tr", text: "Updated Employee Test"
  end
end

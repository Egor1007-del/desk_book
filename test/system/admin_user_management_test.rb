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
    assert_current_path admin_users_path
    assert_selector ".admin-user-form-dialog"
    assert_equal "fixed", page.evaluate_script(
      "getComputedStyle(document.querySelector('#admin_user_form')).position"
    )
    dialog_center = page.evaluate_script(<<~JS)
      (() => {
        const rect = document.querySelector('.admin-user-form-dialog').getBoundingClientRect()
        return [rect.left + rect.width / 2, rect.top + rect.height / 2]
      })()
    JS
    viewport_center = page.evaluate_script("[window.innerWidth / 2, window.innerHeight / 2]")
    assert_in_delta viewport_center.first, dialog_center.first, 2
    assert_in_delta viewport_center.last, dialog_center.last, 2

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
    assert_selector "tr", text: "New Employee Test"
    flash_bottom, actions_top = page.evaluate_script(<<~JS)
      [
        document.querySelector('#flash_messages .alert').getBoundingClientRect().bottom,
        document.querySelector("a[data-turbo-frame='admin_user_form']").getBoundingClientRect().top
      ]
    JS
    assert_operator flash_bottom, :<=, actions_top
    within "#flash_messages" do
      find(".btn-close").click
    end
    assert_no_selector "#flash_messages .alert"

    within("tr", text: "New Employee Test") do
      click_link I18n.t("actions.edit")
    end
    assert_selector "turbo-frame#admin_user_form"
    fill_in "user_last_name", with: "Updated"
    click_button I18n.t("actions.save")

    assert_text I18n.t("flash.users.updated")
    assert_selector "tr", text: "Updated Employee Test"

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

  test "administrator saves a directly opened edit page" do
    employee = create_user(login: "employee", role: :employee, position: @position)
    sign_in_through_ui(@admin)

    visit edit_admin_user_path(employee)
    assert_no_selector "turbo-frame#admin_user_form"
    fill_in "user_last_name", with: "Direct"
    click_button I18n.t("actions.save")

    assert_current_path admin_user_path(employee)
    assert_selector "h1", text: "Direct User"
    assert_text I18n.t("flash.users.updated")
  end

  test "administrator cancels editing without leaving the management page" do
    employee = create_user(login: "employee", role: :employee, position: @position)
    sign_in_through_ui(@admin)
    click_link I18n.t("admin.users.index.title")

    within("tr", text: employee.full_name) do
      click_link I18n.t("actions.edit")
    end
    within "turbo-frame#admin_user_form" do
      assert_selector "form[action='#{admin_user_path(employee)}']"
      click_button I18n.t("actions.cancel")
    end

    assert_current_path admin_users_path
    assert_no_selector "turbo-frame#admin_user_form form"
    assert_selector "tr", text: employee.full_name
  end
end

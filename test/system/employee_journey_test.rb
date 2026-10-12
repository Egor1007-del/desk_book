require "application_system_test_case"

class EmployeeJourneyTest < ApplicationSystemTestCase
  setup do
    @position = Position.create!(name: "Developer")
    @employee = create_user(login: "employee", role: :employee, position: @position)
  end

  test "employee signs in and opens the directory" do
    sign_in_through_ui(@employee)

    visit users_path
    assert_current_path users_path
    assert_selector "h1", text: I18n.t("users.index.title")
    assert_text @employee.full_name
  end

  test "employee switches locale" do
    sign_in_through_ui(@employee)

    visit root_path(locale: :en)
    assert_selector "html[lang='en']"
    assert_text I18n.t("home.title", locale: :en)
  end
end

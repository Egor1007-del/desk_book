require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  private

  def create_user(login:, role:, position:)
    User.new(
      last_name: login.capitalize,
      first_name: "User",
      position: position,
      hired_on: Date.new(2024, 1, 15),
      login: login,
      password: "secret123",
      password_confirmation: "secret123"
    ).tap do |user|
      user.save_with_role!(role: role)
    end
  end

  def sign_in_through_ui(user)
    visit root_path
    fill_in "user_login", with: user.login
    fill_in "user_password", with: "secret123"
    click_button I18n.t("navigation.sign_in")
    assert_text I18n.t("home.title")
    assert_current_path root_path
  end
end

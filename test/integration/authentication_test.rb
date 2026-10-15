require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    position = Position.create!(name: "Developer")
    @user = User.new(
      last_name: "Doe",
      first_name: "John",
      position: position,
      hired_on: Date.new(2024, 1, 15),
      email: "john.doe@example.com",
      login: "john.doe",
      password: "secret123",
      password_confirmation: "secret123"
    )
    @user.save_with_role!(role: :employee)
  end

  test "renders a login form with login and password fields" do
    get new_user_session_path

    assert_response :success
    assert_select "html[lang='ru']"
    assert_select "title", text: I18n.t("sessions.new.title")
    assert_select "input[name='user[login]']"
    assert_select "input[name='user[password]']"
  end

  test "guest layout has home and sign in links" do
    get new_user_session_path

    assert_select "nav[aria-label='#{I18n.t('navigation.main')}']" do
      assert_select "a[href='#{root_path}']", text: I18n.t("navigation.home")
      assert_select "a[href='#{new_user_session_path}']", text: I18n.t("navigation.sign_in")
      assert_select ".language-switcher a", count: 2
      assert_select ".language-switcher a.btn", count: 0
      assert_select "form[action='#{destroy_user_session_path}']", count: 0
    end
  end

  test "switches to English and remembers it in the session" do
    get new_user_session_path(locale: :en)

    assert_select "html[lang='en']"
    assert_select "h1", text: I18n.t("sessions.new.title", locale: :en)

    get new_user_session_path

    assert_select "html[lang='en']"
    assert_select "h1", text: I18n.t("sessions.new.title", locale: :en)
  end

  test "ignores an unsupported locale" do
    get new_user_session_path(locale: :de)

    assert_select "html[lang='ru']"
    assert_select "h1", text: I18n.t("sessions.new.title", locale: :ru)
  end

  test "does not leak locale between browser sessions" do
    english_session = open_session
    russian_session = open_session

    english_session.get new_user_session_path(locale: :en)
    russian_session.get new_user_session_path

    english_session.assert_select "html[lang='en']"
    russian_session.assert_select "html[lang='ru']"
  end

  test "redirects an unauthenticated user to the login page" do
    get root_path

    assert_redirected_to new_user_session_path
  end

  test "routes the browser home page through the web namespace" do
    route = Rails.application.routes.recognize_path("/", method: :get)

    assert_equal "web/home", route.fetch(:controller)
    assert_operator Web::HomeController, :<, Web::ApplicationController
    assert_operator Web::ApplicationController, :<, ApplicationController
  end

  test "signs in with a normalized login and correct password" do
    post user_session_path, params: {
      user: { login: "  JOHN.DOE  ", password: "secret123" }
    }

    assert_redirected_to root_path

    follow_redirect!

    assert_response :success
    assert_select "title", text: "Desk Book"
    assert_select "h1", text: I18n.t("home.title")
    assert_select "p", text: /Doe John/
    assert_select "#flash_messages.flash-messages" do
      assert_select ".alert[data-controller='flash']", text: I18n.t("devise.sessions.signed_in")
      assert_select "button[data-bs-dismiss='alert']", count: 1
    end
  end

  test "signed in layout has home and sign out controls" do
    post user_session_path, params: {
      user: { login: @user.login, password: "secret123" }
    }
    follow_redirect!

    assert_select "nav[aria-label='#{I18n.t('navigation.main')}']" do
      assert_select "a[href='#{root_path}']", text: I18n.t("navigation.home")
      assert_select "form[action='#{destroy_user_session_path}'] button", text: I18n.t("navigation.sign_out")
      assert_select ".language-switcher a", count: 2
      assert_select ".language-switcher a.btn", count: 0
      assert_select "a[href='#{new_user_session_path}']", count: 0

      controls = css_select(".container > div.d-flex.align-items-center.gap-2").first
      assert_equal %w[A SPAN DIV FORM], controls.element_children.map(&:name).map(&:upcase)
    end
  end

  test "home page explains the directory and has interactive guidance" do
    post user_session_path, params: {
      user: { login: @user.login, password: "secret123" }
    }
    follow_redirect!

    assert_select ".home-summary", text: /#{I18n.t('employees.count', count: 1)}/
    assert_select "a[href='https://github.com/Egor1007-del/desk_book'][target='_blank']", text: I18n.t("home.github")
    assert_select "#directory-guide button[data-bs-toggle='collapse']", count: 3
    assert_select "#directory-purpose.collapse.show", text: I18n.t("home.guide.purpose.answer")
  end

  test "does not sign in with an incorrect password" do
    post user_session_path, params: {
      user: { login: @user.login, password: "wrong-password" }
    }

    assert_response :unprocessable_content
    assert_select ".alert-danger", text: I18n.t("devise.failure.invalid")

    get root_path

    assert_redirected_to new_user_session_path
  end

  test "does not use email as an authentication key" do
    post user_session_path, params: {
      user: { login: @user.email, password: "secret123" }
    }

    assert_response :unprocessable_content

    get root_path

    assert_redirected_to new_user_session_path
  end

  test "does not expose registration or password recovery routes" do
    get "/users/sign_up"
    assert_redirected_to new_user_session_path

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/password/new", method: :get)
    end
  end

  test "signs out an authenticated user" do
    post user_session_path, params: {
      user: { login: @user.login, password: "secret123" }
    }

    delete destroy_user_session_path

    assert_redirected_to root_path

    get root_path

    assert_redirected_to new_user_session_path
  end
end

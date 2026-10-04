require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    position = Position.create!(name: "Developer")
    @user = User.create_with_role!(
      {
        last_name: "Doe",
        first_name: "John",
        position: position,
        hired_on: Date.new(2024, 1, 15),
        email: "john.doe@example.com",
        login: "john.doe",
        password: "secret123",
        password_confirmation: "secret123"
      },
      role: :employee
    )
  end

  test "renders a login form with login and password fields" do
    get new_user_session_path

    assert_response :success
    assert_select "title", text: "Sign in"
    assert_select "input[name='user[login]']"
    assert_select "input[name='user[password]']"
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
    assert_select "title", text: "Employee directory"
    assert_select "h1", text: "Employee directory"
    assert_select "p", text: /Doe John/
  end

  test "does not sign in with an incorrect password" do
    post user_session_path, params: {
      user: { login: @user.login, password: "wrong-password" }
    }

    assert_response :unprocessable_content
    assert_select ".alert-danger", text: /Invalid login or password/

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
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/users/sign_up", method: :get)
    end

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

module Web
  class ApplicationController < ::ApplicationController
    include Pagy::Method
    include Pundit::Authorization

    layout "web/application"

    around_action :switch_locale
    before_action :authenticate_user!, unless: :devise_controller?
    after_action :verify_authorized, unless: :devise_controller?

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    # Only allow browsers that support the features used by the web interface.
    allow_browser versions: :modern

    # Changes to the importmap invalidate cached web responses.
    stale_when_importmap_changes

    private

    def switch_locale(&action)
      requested_locale = params[:locale]&.to_sym
      session[:locale] = requested_locale if I18n.available_locales.include?(requested_locale)

      locale = session[:locale]&.to_sym
      locale = I18n.default_locale unless I18n.available_locales.include?(locale)
      Pagy::I18n.locale = locale
      I18n.with_locale(locale, &action)
    ensure
      Pagy::I18n.locale = nil
    end

    helper_method def locale_switch_path(locale)
      return root_path(locale: locale) unless request.get?

      query = request.query_parameters.merge(locale: locale).to_query
      "#{request.path}?#{query}"
    end

    def user_not_authorized
      redirect_to root_path, alert: t("authorization.denied")
    end
  end
end

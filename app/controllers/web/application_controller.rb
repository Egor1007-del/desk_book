module Web
  class ApplicationController < ::ApplicationController
    include Pundit::Authorization

    layout "web/application"

    before_action :authenticate_user!, unless: :devise_controller?
    after_action :verify_authorized, unless: :devise_controller?

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    # Only allow browsers that support the features used by the web interface.
    allow_browser versions: :modern

    # Changes to the importmap invalidate cached web responses.
    stale_when_importmap_changes

    private

    def user_not_authorized
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end
end

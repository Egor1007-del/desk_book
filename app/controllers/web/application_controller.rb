module Web
  class ApplicationController < ::ApplicationController
    layout "web/application"

    before_action :authenticate_user!, unless: :devise_controller?

    # Only allow browsers that support the features used by the web interface.
    allow_browser versions: :modern

    # Changes to the importmap invalidate cached web responses.
    stale_when_importmap_changes
  end
end

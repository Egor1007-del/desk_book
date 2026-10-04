module Web
  class HomeController < ApplicationController
    def index
      authorize :home, :show?
    end
  end
end

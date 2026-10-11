module Web
  class HomeController < ApplicationController
    def index
      authorize :home, :show?
      @employees_count = Position.sum(:users_count)
    end
  end
end

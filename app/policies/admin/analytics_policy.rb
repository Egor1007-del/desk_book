module Admin
  class AnalyticsPolicy < ApplicationPolicy
    def show?
      admin?
    end
  end
end

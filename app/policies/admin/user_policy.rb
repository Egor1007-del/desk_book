module Admin
  class UserPolicy < ::UserPolicy
    ATTRIBUTES = %i[
      last_name
      first_name
      middle_name
      position_id
      hired_on
      phone
      email
      login
      password
      password_confirmation
    ].freeze

    def index?
      admin?
    end

    def show?
      admin?
    end

    def create?
      admin?
    end

    def update?
      admin?
    end

    def destroy?
      admin? && another_admin_remains?
    end

    def change_role?
      admin? && another_admin_remains?
    end

    def permitted_attributes
      admin? ? ATTRIBUTES : []
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        user.has_role?(:admin) ? scope.all : scope.none
      end
    end

    private

    def another_admin_remains?
      !record.has_role?(:admin) || User.with_role(:admin).where.not(id: record.id).exists?
    end
  end
end

class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def export?
    true
  end

  def show_login?
    admin?
  end

  def show_role?
    admin?
  end

  def show_password?
    false
  end

  def show_encrypted_password?
    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end

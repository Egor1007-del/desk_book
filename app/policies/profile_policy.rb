class ProfilePolicy < ApplicationPolicy
  ATTRIBUTES = %i[phone email login password password_confirmation].freeze

  def edit?
    owner?
  end

  def update?
    owner?
  end

  def permitted_attributes
    owner? ? ATTRIBUTES : []
  end

  private

  def owner?
    user == record
  end
end

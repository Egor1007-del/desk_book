class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :validatable, authentication_keys: [ :login ]

  belongs_to :position, inverse_of: :users

  before_validation :normalize_login

  validates :last_name, :first_name, :hired_on, :login, presence: true
  validates :login, uniqueness: { case_sensitive: false }

  def full_name
    [ last_name, first_name, middle_name ].compact_blank.join(" ")
  end

  def self.create_with_role!(attributes, role:)
    transaction do
      create!(attributes).tap { |user| user.assign_role!(role) }
    end
  end

  def update_with_role!(attributes, role:)
    transaction do
      update!(attributes)
      assign_role!(role)
    end
  end

  def assign_role!(role)
    role_name = role.to_s
    raise ArgumentError, "Unknown role: #{role_name}" unless Role::NAMES.include?(role_name)

    transaction do
      roles.clear
      assigned_role = add_role(role_name)
      raise ActiveRecord::RecordInvalid, assigned_role unless assigned_role.persisted? && has_role?(role_name)
    end

    self
  end

  protected

  def email_required?
    false
  end

  private

  def normalize_login
    self.login = login&.strip&.downcase
  end
end

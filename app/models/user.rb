class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :validatable, authentication_keys: [ :login ]

  belongs_to :position, inverse_of: :users

  before_validation :normalize_login

  validates :last_name, :first_name, :hired_on, :login, presence: true
  validates :login, uniqueness: { case_sensitive: false }
  validates :password_confirmation, presence: true, if: -> { password.present? }
  validates :role_name, inclusion: { in: Role::NAMES }, if: -> { defined?(@role_name) }

  def full_name
    [ last_name, first_name, middle_name ].compact_blank.join(" ")
  end

  def role_name
    defined?(@role_name) ? @role_name : roles.first&.name
  end

  def role_name=(name)
    @role_name = name
  end

  def save_with_role!(attributes = {}, role:)
    assign_attributes(attributes)
    self.role_name = role.to_s

    transaction do
      lock_admin_role!
      save!
      ensure_admin_remains!(role_name)
      replace_role!(role_name) unless has_role?(role_name)
    end

    self
  end

  def destroy_with_role_safety!
    transaction do
      lock_admin_role!
      ensure_admin_remains!(:removed)
      destroy!
    end
  end

  protected

  def email_required?
    false
  end

  private

  def replace_role!(new_role_name)
    roles.clear
    assigned_role = add_role(new_role_name)
    raise ActiveRecord::RecordInvalid, assigned_role unless assigned_role.persisted? && has_role?(new_role_name)
  end

  def ensure_admin_remains!(next_role)
    return unless has_role?(:admin)
    return if next_role.to_s == "admin"
    return if User.with_role(:admin).where.not(id: id).exists?

    errors.add(:role_name, "cannot remove the last administrator")
    raise ActiveRecord::RecordInvalid, self
  end

  def lock_admin_role!
    Role.lock.find_by(name: "admin")
  end

  def normalize_login
    self.login = login&.strip&.downcase
  end
end

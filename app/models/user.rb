class User < ApplicationRecord
  belongs_to :position, inverse_of: :users

  before_validation :normalize_login

  validates :last_name, :first_name, :hired_on, :login, presence: true
  validates :login, uniqueness: { case_sensitive: false }

  def full_name
    [ last_name, first_name, middle_name ].compact_blank.join(" ")
  end

  private

  def normalize_login
    self.login = login&.strip&.downcase
  end
end

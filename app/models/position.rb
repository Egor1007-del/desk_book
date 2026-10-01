class Position < ApplicationRecord
  has_many :users,
    inverse_of: :position,
    dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end

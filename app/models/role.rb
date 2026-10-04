class Role < ApplicationRecord
  NAMES = %w[admin employee].freeze

  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
    polymorphic: true,
    optional: true

  validates :name, inclusion: { in: NAMES }, uniqueness: true
  validates :resource_type, :resource_id, absence: true

  scopify
end

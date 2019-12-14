# frozen_string_literal: true
class Packages::DependencyLink < ApplicationRecord
  belongs_to :package, inverse_of: :dependency_links
  belongs_to :dependency, inverse_of: :dependency_links, class_name: 'Packages::Dependency'

  validates :package, :dependency, presence: true

  validates :dependency_type,
    uniqueness: { scope: %i[package_id dependency_id] }

  enum dependency_type: { dependencies: 1, devDependencies: 2, bundleDependencies: 3, peerDependencies: 4, deprecated: 5 }

  scope :with_dependency_type, ->(dependency_type) { where(dependency_type: dependency_type) }
  scope :includes_dependency, -> { includes(:dependency) }
end

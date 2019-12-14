# frozen_string_literal: true

class Packages::ConanMetadatum < ApplicationRecord
  belongs_to :package, inverse_of: :conan_metadatum

  validates :package, presence: true

  validates :package_username,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_component_regex }

  validates :package_channel,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_component_regex }

  def recipe
    "#{package.name}/#{package.version}@#{package_username}/#{package_channel}"
  end

  def recipe_path
    recipe.tr('@', '/')
  end

  def self.package_username_from(full_path:)
    full_path.tr('/', '+')
  end

  def self.full_path_from(package_username:)
    package_username.tr('+', '/')
  end
end

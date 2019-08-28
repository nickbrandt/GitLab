# frozen_string_literal: true
class Packages::Package < ApplicationRecord
  belongs_to :project
  # package_files must be destroyed by ruby code in order to properly remove carrierwave uploads and update project statistics
  has_many :package_files, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :maven_metadatum, inverse_of: :package

  accepts_nested_attributes_for :maven_metadatum

  validates :project, presence: true

  validates :name,
    presence: true,
    format: { with: Gitlab::Regex.package_name_regex }

  validate :valid_npm_package_name, if: :npm?
  validate :package_already_taken, if: :npm?

  enum package_type: { maven: 1, npm: 2 }

  scope :with_name, ->(name) { where(name: name) }
  scope :with_version, ->(version) { where(version: version) }
  scope :has_version, -> { where.not(version: nil) }
  scope :preload_files, -> { preload(:package_files) }
  scope :last_of_each_version, -> { where(id: all.select('MAX(id) AS id').group(:version)) }

  def self.for_projects(projects)
    return none unless projects.any?

    where(project_id: projects)
  end

  def self.only_maven_packages_with_path(path)
    joins(:maven_metadatum).where(packages_maven_metadata: { path: path })
  end

  def self.by_name_and_file_name(name, file_name)
    with_name(name)
      .joins(:package_files)
      .where(packages_package_files: { file_name: file_name }).last!
  end

  private

  def valid_npm_package_name
    return unless project&.root_namespace

    unless name =~ %r{\A@#{project.root_namespace.path}/[^/]+\z}
      errors.add(:name, 'is not valid')
    end
  end

  def package_already_taken
    return unless project

    if project.package_already_taken?(name)
      errors.add(:base, 'Package already exists')
    end
  end
end

# frozen_string_literal: true
class Packages::Package < ActiveRecord::Base
  belongs_to :project
  has_many :package_files
  has_one :maven_metadatum, inverse_of: :package

  accepts_nested_attributes_for :maven_metadatum

  validates :project, presence: true

  validates :name,
    presence: true,
    format: { with: Gitlab::Regex.package_name_regex }

  enum package_type: { maven: 1, npm: 2 }

  scope :with_name, ->(name) { where(name: name) }
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
end

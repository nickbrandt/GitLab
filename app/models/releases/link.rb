# frozen_string_literal: true

module Releases
  class Link < ApplicationRecord
    self.table_name = 'release_links'

    belongs_to :release

    FILEPATH_REGEX = /\A[\w]+([\-\.\/\w])*[\da-zA-Z]+\z/.freeze

    validates :url, presence: true, addressable_url: { schemes: %w(http https ftp) }, uniqueness: { scope: :release }
    validates :name, presence: true, uniqueness: { scope: :release }
    validates :filepath, uniqueness: { scope: :release }, format: { with: FILEPATH_REGEX }, allow_blank: true

    scope :sorted, -> { order(created_at: :desc) }

    def internal?
      url.start_with?(release.project.web_url)
    end

    def external?
      !internal?
    end

    def filepath_url
      return url unless filepath

      project = release.project
      "#{Gitlab::Routing.url_helpers.namespace_project_release_url(project.namespace_id, project, release)}/#{filepath}"
    end
  end
end

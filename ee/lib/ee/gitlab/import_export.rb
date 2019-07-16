# frozen_string_literal: true

module EE::Gitlab::ImportExport
  extend ActiveSupport::Concern

  prepended do
    def design_repo_bundle_filename
      'project.design.bundle'
    end
  end
end

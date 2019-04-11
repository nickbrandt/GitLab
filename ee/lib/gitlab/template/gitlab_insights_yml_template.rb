# frozen_string_literal: true

module Gitlab
  module Template
    class GitlabInsightsYmlTemplate < BaseTemplate
      class << self
        def extension
          '.yml'
        end

        def categories
          {}
        end

        def base_dir
          Rails.root.join('ee/fixtures/insights')
        end

        def finder(project = nil)
          Gitlab::Template::Finders::GlobalTemplateFinder.new(
            base_dir, extension, categories)
        end
      end
    end
  end
end

# frozen_string_literal: true

module EE
  module Search
    module GlobalService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :execute
      def execute
        if ::Gitlab::CurrentSettings.elasticsearch_search?
          ::Gitlab::Elastic::SearchResults.new(current_user, params[:search], elastic_projects, elastic_global)
        else
          super
        end
      end

      def elastic_projects
        strong_memoize(:elastic_projects) do
          if current_user&.full_private_access?
            :any
          elsif current_user
            current_user.authorized_projects.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
          else
            []
          end
        end
      end

      def elastic_global
        true
      end

      override :allowed_scopes
      def allowed_scopes
        strong_memoize(:ee_allowed_scopes) do
          super.tap do |ce_scopes|
            ce_scopes.concat(%w[wiki_blobs blobs commits]) if ::Gitlab::CurrentSettings.elasticsearch_search?
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module EE
  module Git
    module WikiPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        return unless project.use_elasticsearch?
        return unless default_branch_changes.any?

        project.wiki.index_wiki_blobs
      end
    end
  end
end

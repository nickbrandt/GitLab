# frozen_string_literal: true

module EE
  module Git
    module WikiPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        return unless project.use_elasticsearch?

        # For all changes on the default branch (usually master) trigger an ES update
        default_branch_changes.each do |change|
          project.wiki.index_wiki_blobs(change[:newrev])
        end
      end
    end
  end
end

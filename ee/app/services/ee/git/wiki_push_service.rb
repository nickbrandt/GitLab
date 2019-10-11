# frozen_string_literal: true

module EE
  module Git
    module WikiPushService
      def execute
        super

        return unless project.use_elasticsearch?

        # Check if one of the changes we got was for the default branch. If it was, trigger an ES update
        params[:changes].each do |change|
          branch_name = ::Gitlab::Git.ref_name(change[:ref])
          next unless project.wiki.default_branch == branch_name

          project.wiki.index_wiki_blobs(change[:newrev])
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    class MergeRequestBasic < IssuableEntity
      # Evaluate the lazy exposures to trigger the BatchLoader
      # before any object is serialized.
      def presented
        lazy_merge_request_metrics
        lazy_diff
        lazy_assignees
        lazy_author
        lazy_milestone
        lazy_labels

        # TODO: we could have a `:batch` exposure option to automatically scan
        # exposures and evaluate the block so that the BatchLoader is primed
        time_stats = self.class.find_exposure(:time_stats)
        Object.const_get(time_stats.using_class_name, false).new(object).presented

        super
      end

      expose :merged_by, using: Entities::UserBasic do |merge_request, _options|
        lazy_merge_request_metrics&.merged_by
      end
      expose :merged_at do |merge_request, _options|
        lazy_merge_request_metrics&.merged_at
      end
      expose :closed_by, using: Entities::UserBasic do |merge_request, _options|
        lazy_merge_request_metrics&.latest_closed_by
      end
      expose :closed_at do |merge_request, _options|
        lazy_merge_request_metrics&.latest_closed_at
      end
      expose :title_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :title)
      end
      expose :description_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :description)
      end
      expose :target_branch, :source_branch
      expose(:user_notes_count) { |merge_request, options| issuable_metadata.user_notes_count }
      expose(:upvotes)          { |merge_request, options| issuable_metadata.upvotes }
      expose(:downvotes)        { |merge_request, options| issuable_metadata.downvotes }

      with_options using: Entities::UserBasic do
        expose :lazy_author, as: :author
        expose :lazy_assignees, as: :assignees
        expose :lazy_assignee, as: :assignee do |merge_request, options|
          lazy_assignees.first
        end
      end

      expose :source_project_id, :target_project_id
      expose :labels do |merge_request, options|
        lazy_labels do |label|
          if options[:with_labels_details]
            Entities::LabelBasic.new(label)
          else
            label.title
          end
        end
      end
      expose :work_in_progress?, as: :work_in_progress
      expose :lazy_milestone, as: :milestone, using: Entities::Milestone
      expose :merge_when_pipeline_succeeds

      # Ideally we should deprecate `MergeRequest#merge_status` exposure and
      # use `MergeRequest#mergeable?` instead (boolean).
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/42344 for more
      # information.
      #
      # For list endpoints, we skip the recheck by default, since it's expensive
      expose :merge_status do |merge_request, options|
        merge_request.check_mergeability(async: true) unless options[:skip_merge_status_recheck]
        merge_request.public_merge_status
      end
      expose :diff_head_sha, as: :sha do |_, options|
        lazy_diff.read_attribute(:head_commit_sha)
      end
      expose :merge_commit_sha
      expose :squash_commit_sha
      expose :discussion_locked
      expose :should_remove_source_branch?, as: :should_remove_source_branch
      expose :force_remove_source_branch?, as: :force_remove_source_branch

      with_options if: -> (merge_request, _) { merge_request.for_fork? } do
        expose :allow_collaboration
        # Deprecated
        expose :allow_collaboration, as: :allow_maintainer_to_push
      end

      # reference is deprecated in favour of references
      # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
      expose :reference do |merge_request, options|
        merge_request.to_reference(options[:project])
      end

      expose :references, with: IssuableReferences do |merge_request|
        merge_request
      end

      expose :web_url do |merge_request|
        Gitlab::UrlBuilder.build(merge_request)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |merge_request|
        merge_request
      end

      expose :squash
      expose :task_completion_status
      expose :cannot_be_merged?, as: :has_conflicts
      expose :mergeable_discussions_state?, as: :blocking_discussions_resolved

      private

      def lazy_merge_request_metrics
        BatchLoader.for(object.id).batch(key: :merge_request_metrics) do |models, loader|
          ::MergeRequest::Metrics
            .preloaded
            .for_merge_requests(models)
            .find_each do |metric|
            loader.call(metric.merge_request_id, metric)
          end
        end
      end

      def lazy_diff
        BatchLoader.for(object.id).batch(key: :merge_request_diff) do |ids, loader|
          ::MergeRequestDiff
            .for_merge_requests(ids)
            .find_each do |diff|
            loader.call(diff.merge_request_id, diff)
          end
        end
      end

      def lazy_assignees
        BatchLoader.for(object.id).batch(key: :assignees, default_value: []) do |ids, loader|
          ::MergeRequestAssignee
            .preloaded
            .for_merge_requests(ids)
            .find_each do |assignment|
            loader.call(assignment.merge_request_id) { |acc| acc << assignment.assignee }
          end
        end
      end

      def lazy_author
        BatchLoader.for(object.author_id).batch(key: :author) do |ids, loader|
          ::User.id_in(ids).find_each do |author|
            loader.call(author.id, author)
          end
        end
      end

      def lazy_milestone
        BatchLoader.for(object.milestone_id).batch(key: :milestone) do |ids, loader|
          ::Milestone
            .with_api_entity_associations
            .id_in(ids)
            .find_each do |milestone|
            loader.call(milestone.id, milestone)
          end
        end
      end

      def lazy_labels(&block)
        BatchLoader.for(object.id).batch(key: :labels, default_value: []) do |ids, loader|
          ::LabelLink
            .preloaded
            .for_merge_requests(ids)
            .find_each do |link|
            loader.call(link.target_id) do |memo|
              memo << yield(link.label)
            end
          end
        end
      end
    end
  end
end

API::Entities::MergeRequestBasic.prepend_if_ee('EE::API::Entities::MergeRequestBasic', with_descendants: true)

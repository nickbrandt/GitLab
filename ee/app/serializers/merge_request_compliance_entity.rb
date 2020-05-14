# frozen_string_literal: true

class MergeRequestComplianceEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :title
  expose :merged_at
  expose :milestone

  expose :path do |merge_request|
    merge_request_path(merge_request)
  end

  expose :issuable_reference do |merge_request|
    merge_request.to_reference(merge_request.project.group)
  end

  expose :approved_by_users, using: API::Entities::UserBasic

  expose :pipeline_status, if: -> (*) { can_read_pipeline? }, with: DetailedStatusEntity

  private

  alias_method :merge_request, :object

  def can_read_pipeline?
    can?(request.current_user, :read_pipeline, merge_request.head_pipeline)
  end

  def pipeline_status
    merge_request.head_pipeline.detailed_status(request.current_user)
  end
end

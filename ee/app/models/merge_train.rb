# frozen_string_literal: true

class MergeTrain < ApplicationRecord
  include AfterCommitQueue

  belongs_to :target_project, class_name: "Project"
  belongs_to :merge_request, inverse_of: :merge_train
  belongs_to :user
  belongs_to :pipeline, class_name: 'Ci::Pipeline'

  after_commit :cleanup_ref, if: -> { saved_change_to_status? && merged? }
  after_commit :refresh_async, if: -> { saved_change_to_status? && stale? }

  after_destroy do |merge_train|
    run_after_commit do
      merge_train.pipeline&.cancel_running(retries: 1)
      merge_train.cleanup_ref
    end
  end

  enum status: %i[created merged stale fresh]

  scope :active, -> { where(status: active_statuses) }
  scope :merged, -> { where(status: merged_statuses) }
  scope :for_target, -> (project_id, branch) { where(target_project_id: project_id, target_branch: branch) }
  scope :by_id, -> { order('merge_trains.id ASC') }

  class << self
    def all_active_mrs_in_train(target_project_id, target_branch)
      MergeRequest.joins(:merge_train).merge(
        MergeTrain.active.for_target(target_project_id, target_branch).by_id
      )
    end

    def first_in_train(target_project_id, target_branch)
      all_active_mrs_in_train(target_project_id, target_branch).first
    end

    def first_in_trains(project)
      MergeRequest.preload(:target_project).where(id: first_merge_request_ids(project))
    end

    def first_in_train_from(merge_request_ids)
      merge_request = MergeRequest.find(merge_request_ids.first)
      all_active_mrs_in_train(merge_request.target_project_id, merge_request.target_branch).where(id: merge_request_ids).first
    end

    def last_merged_mr_in_train(target_project_id, target_branch)
      MergeRequest.where(id: last_merged_merge_train(target_project_id, target_branch)).take
    end

    def sha_exists_in_history?(target_project_id, target_branch, newrev, limit: 20)
      MergeRequest.exists?(id: merged_merge_trains(target_project_id, target_branch, limit: limit),
                           merge_commit_sha: newrev)
    end

    def total_count_in_train(merge_request)
      all_active_mrs_in_train(merge_request.target_project_id, merge_request.target_branch).count
    end

    def active_statuses
      statuses.values_at(:created, :stale, :fresh)
    end

    def merged_statuses
      statuses.values_at(:merged)
    end

    private

    def first_merge_request_ids(project)
      MergeTrain.where(target_project: project)
        .active
        .select('DISTINCT ON (target_branch) merge_request_id')
        .order(:target_branch, :id)
    end

    def last_merged_merge_train(target_project_id, target_branch)
      merged_merge_trains(target_project_id, target_branch, limit: 1)
    end

    def merged_merge_trains(target_project_id, target_branch, limit:)
      MergeTrain.for_target(target_project_id, target_branch)
        .merged.order(id: :desc).select(:merge_request_id).limit(limit)
    end
  end

  def all_next
    self.class.all_active_mrs_in_train(target_project_id, target_branch).where('merge_trains.id > ?', id)
  end

  def all_prev
    self.class.all_active_mrs_in_train(target_project_id, target_branch).where('merge_trains.id < ?', id)
  end

  def next
    all_next.first
  end

  def prev
    all_prev.last
  end

  def index
    all_prev.count
  end

  def first_in_train?
    !follower_in_train?
  end

  def follower_in_train?
    all_prev.exists?
  end

  def cleanup_ref
    merge_request.cleanup_refs(only: :train)
  end

  private

  def refresh_async
    AutoMergeProcessWorker.perform_async(merge_request_id)
  end
end

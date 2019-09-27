# frozen_string_literal: true

class MergeTrain < ApplicationRecord
  include AfterCommitQueue

  belongs_to :target_project, class_name: "Project"
  belongs_to :merge_request
  belongs_to :user
  belongs_to :pipeline, class_name: 'Ci::Pipeline'

  after_destroy do |merge_train|
    run_after_commit { merge_train.merge_request.cleanup_refs(only: :train) }
  end

  class << self
    def all_in_train(merge_request)
      joined_merge_requests(merge_request).order('merge_trains.id ASC')
    end

    def first_in_train(merge_request)
      all_in_train(merge_request).first
    end

    def first_in_trains(project)
      MergeRequest.preload(:target_project).where(id: first_merge_request_ids(project))
    end

    def first_in_train_from(merge_request_ids)
      merge_request = MergeRequest.find(merge_request_ids.first)
      all_in_train(merge_request).where(id: merge_request_ids).first
    end

    def total_count_in_train(merge_request)
      all_in_train(merge_request).count
    end

    def joined_merge_requests(merge_request)
      MergeRequest.joins(:merge_train)
        .where('merge_requests.target_project_id = ?', merge_request.target_project_id)
        .where('merge_requests.target_branch = ?', merge_request.target_branch)
    end

    private

    def first_merge_request_ids(project)
      MergeTrain.where(target_project: project)
        .select('DISTINCT ON (target_branch) merge_request_id')
        .order(:target_branch, :id)
    end
  end

  def all_next
    self.class.all_in_train(merge_request).where('merge_trains.id > ?', id)
  end

  def all_prev
    self.class.all_in_train(merge_request).where('merge_trains.id < ?', id)
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
end

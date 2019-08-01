# frozen_string_literal: true

class MergeRequest::Metrics < ApplicationRecord
  include EachBatch

  belongs_to :merge_request
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id
  belongs_to :latest_closed_by, class_name: 'User'
  belongs_to :merged_by, class_name: 'User'

  scope :merged_after, -> (date) { where('merged_at >= ?', date) }
end

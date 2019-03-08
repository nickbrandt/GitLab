# frozen_string_literal: true

class Insight < ActiveRecord::Base
  belongs_to :group, foreign_key: :namespace_id
  belongs_to :project
end

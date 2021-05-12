# frozen_string_literal: true

module Ci
  class PendingBuild < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'
  end
end

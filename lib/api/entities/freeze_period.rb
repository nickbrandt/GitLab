# frozen_string_literal: true

module API
  module Entities
    class ProjectFreezePeriod < Grape::Entity
      expose :id, :project_id
      expose :freeze_start, :freeze_end, :timezone
      expose :created_at, :updated_at
    end
  end
end

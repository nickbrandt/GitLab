# frozen_string_literal: true

module EE
  module API
    module Entities
      class FeatureFlag < Grape::Entity
        class UserList < Grape::Entity
          expose :id
          expose :iid
          expose :project_id
          expose :created_at
          expose :updated_at
          expose :name
          expose :user_xids
        end
      end
    end
  end
end

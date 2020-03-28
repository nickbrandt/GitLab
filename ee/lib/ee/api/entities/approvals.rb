# frozen_string_literal: true

module EE
  module API
    module Entities
      class Approvals < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end
    end
  end
end

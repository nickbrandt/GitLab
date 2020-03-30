# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserPath
        extend ActiveSupport::Concern

        prepended do
          expose :gitlab_employee?, as: :is_gitlab_employee
        end
      end
    end
  end
end

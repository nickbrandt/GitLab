# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserWithAdmin
        extend ActiveSupport::Concern

        prepended do
          expose :note
        end
      end
    end
  end
end

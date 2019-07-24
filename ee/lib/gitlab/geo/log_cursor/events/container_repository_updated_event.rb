# frozen_string_literal: true

module Gitlab
  module Geo
    module LogCursor
      module Events
        class ContainerRepositoryUpdatedEvent
          include BaseEvent

          def process
          end
        end
      end
    end
  end
end

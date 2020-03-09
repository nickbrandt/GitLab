# frozen_string_literal: true

module EE
  module API
    module Entities
      class UnleashStrategy < Grape::Entity
        expose :name do |strategy|
          if strategy.respond_to?(:name)
            strategy.name
          else
            strategy['name']
          end
        end
        expose :parameters do |strategy|
          if strategy.respond_to?(:parameters)
            strategy.parameters
          else
            strategy['parameters']
          end
        end
      end
    end
  end
end

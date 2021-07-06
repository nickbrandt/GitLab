# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents mirroring the status of another project pipeline.
          #
          class Status < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, type: String, presence: true
            end

            def value
              { project: @config }
            end
          end
        end
      end
    end
  end
end

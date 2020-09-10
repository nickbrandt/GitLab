# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a secrets definition.
        #
        class Secrets < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Configurable

          validations do
            validates :config, type: Hash
          end

          entries Entry::Secret, description: "%s secret definition"
        end
      end
    end
  end
end

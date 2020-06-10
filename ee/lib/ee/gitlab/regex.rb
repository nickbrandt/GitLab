# frozen_string_literal: true

module EE
  module Gitlab
    module Regex
      extend ActiveSupport::Concern

      class_methods do
        def feature_flag_regex
          /\A[a-z]([-_a-z0-9]*[a-z0-9])?\z/
        end

        def feature_flag_regex_message
          "can contain only lowercase letters, digits, '_' and '-'. " \
          "Must start with a letter, and cannot end with '-' or '_'"
        end
      end
    end
  end
end

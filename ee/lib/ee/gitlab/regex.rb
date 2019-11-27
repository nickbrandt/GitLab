# frozen_string_literal: true

module EE
  module Gitlab
    module Regex
      extend ActiveSupport::Concern

      class_methods do
        def package_name_regex
          @package_name_regex ||= %r{\A\@?(([\w\-\.\+]*)\/)*([\w\-\.]+)@?(([\w\-\.\+]*)\/)*([\w\-\.]*)\z}.freeze
        end

        def maven_file_name_regex
          @maven_file_name_regex ||= %r{^[A-Za-z0-9\.\_\-\+]+$}.freeze
        end

        def maven_path_regex
          @maven_path_regex ||= %r{\A\@?(([\w\-\.]*)/)*([\w\-\.\+]*)\z}.freeze
        end

        def maven_app_name_regex
          @maven_app_name_regex ||= /\A[\w\-\.]+\z/.freeze
        end

        def maven_app_group_regex
          maven_app_name_regex
        end

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

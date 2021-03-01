# frozen_string_literal: true

module Gitlab
  module Pages
    class Settings < ::SimpleDelegator
      DiskAccessDenied = Class.new(StandardError)

      def self.build_path_for(path_value)
        if !path_value && path_value.to_s == 'false'
          false
        else
          ::Settings.absolute(path_value || File.join(::Settings.shared['path'], "pages"))
        end
      end

      def path
        if ::Gitlab::Runtime.web_server? && !::Gitlab::Runtime.test_suite?
          raise DiskAccessDenied
        end

        super
      end
    end
  end
end

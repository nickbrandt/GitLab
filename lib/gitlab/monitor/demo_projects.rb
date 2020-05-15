# frozen_string_literal: true

module Gitlab
  module Monitor
    module DemoProjects
      DOT_COM_IDS = [14986497, 12507547].freeze
      STAGING_IDS = [4422333].freeze

      def self.primary_keys
        if ::Gitlab.com?
          DOT_COM_IDS
        elsif ::Gitlab.staging?
          STAGING_IDS
        elsif Rails.env.development? || Rails.env.test?
          Project.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
        end || []
      end
    end
  end
end

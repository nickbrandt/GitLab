# frozen_string_literal: true

module Elastic
  class Migration
    attr_reader :version

    def initialize(version)
      @version = version
    end

    def migrate
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    def completed?
      raise NotImplementedError, 'Please extend Elastic::Migration'
    end

    private

    def helper
      @helper ||= Gitlab::Elastic::Helper.default
    end

    def client
      helper.client
    end

    def log(message)
      logger.info "[Elastic::Migration: #{self.version}] #{message}"
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end

    def current_properties
      current_mappings = helper.get_mappings

      # ES7 and ES6 have different mappings responses
      if Gitlab::VersionInfo.parse(client.info['version']['number']).major == 7
        current_mappings['properties']
      else
        current_mappings['doc']['properties']
      end
    end
  end
end

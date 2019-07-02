# frozen_string_literal: true

# Stores stable methods for ApplicationClassProxy
# which is unlikely to change from version to version.
module Elastic
  module ClassProxyUtil
    extend ActiveSupport::Concern

    def initialize(target)
      super(target)

      config = version_namespace.const_get('Config')

      @index_name = config.index_name
      @document_type = config.document_type
      @settings = config.settings
      @mapping = config.mapping
    end

    ### Multi-version utils

    alias_method :real_class, :class

    def version_namespace
      self.class.parent
    end

    class_methods do
      def write_methods
        %i(import create_index! delete_index! refresh_index!)
      end
    end
  end
end

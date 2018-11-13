# frozen_string_literal: true

module EE
  module Key
    extend ActiveSupport::Concern

    class_methods do
      def regular_keys
        where(type: ['LDAPKey', 'Key', nil])
      end
    end
  end
end

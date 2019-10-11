# frozen_string_literal: true

module EE
  module Key
    extend ActiveSupport::Concern

    prepended do
      include UsageStatistics

      scope :ldap, -> { where(type: 'LDAPKey') }
    end

    class_methods do
      def regular_keys
        where(type: ['LDAPKey', 'Key', nil])
      end
    end
  end
end

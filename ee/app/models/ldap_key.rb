# frozen_string_literal: true

class LDAPKey < Key
  include EE::UsageStatistics # rubocop: disable Cop/InjectEnterpriseEditionModule

  def can_delete?
    false
  end
end

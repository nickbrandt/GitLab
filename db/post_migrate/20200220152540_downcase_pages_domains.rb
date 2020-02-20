# frozen_string_literal: true

class DowncasePagesDomains < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class PagesDomain < ActiveRecord::Base
    self.table_name = 'pages_domains'
    self.inheritance_column = :_type_disabled
  end

  def up
    # clean all possible duplicates
    PagesDomain.joins('JOIN pages_domains as d2 on pages_domains.id < d2.id AND lower(pages_domains.domain) = lower(d2.domain)').delete_all

    update_value = Arel.sql('lower(domain)')
    update_column_in_batches('pages_domains', :domain, update_value)
  end

  def down
  end
end

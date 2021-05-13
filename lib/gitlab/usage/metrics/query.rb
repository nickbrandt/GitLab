# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      class Query
        def raw_sql(relation, column, distinct = false)
          column ||= relation.primary_key
          relation.select(relation.all.table[column].count(distinct)).to_sql
        end
      end
    end
  end
end

# frozen_string_literal: true

# Statement timeout helpers
module Gitlab
  module Database
    module Timeout
      def self.with_statement_timeout(timeout_ms = 15000)
        raise 'Cannot call with_timeout_timeout() without a block' unless block_given?

        if ActiveRecord::Base.connection.transaction_open?
          yield
        else
          ActiveRecord::Base.connection.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout TO #{timeout_ms}")

            yield
          end
        end
      end
    end
  end
end

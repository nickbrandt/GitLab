# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :read_only?
        def read_only?
          ::Gitlab::Geo.secondary?
        end

        def healthy?
          !Postgresql::ReplicationSlot.lag_too_great?
        end

        # Disables prepared statements for the current database connection.
        def disable_prepared_statements
          config = ActiveRecord::Base.configurations[Rails.env]
          config['prepared_statements'] = false

          ActiveRecord::Base.establish_connection(config)
        end

        def geo_uncached_queries
          raise 'No block given' unless block_given?

          Geo::TrackingBase.uncached do
            ActiveRecord::Base.uncached do
              yield
            end
          end
        end
      end
    end
  end
end

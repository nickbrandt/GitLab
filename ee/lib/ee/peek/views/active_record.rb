# frozen_string_literal: true

module EE
  module Peek
    module Views
      module ActiveRecord
        extend ::Gitlab::Utils::Override

        override :generate_detail
        def generate_detail(start, finish, data)
          detail = super

          if ::Gitlab::Database::LoadBalancing.enable?
            detail[:db_role] = ::Gitlab::Database::LoadBalancing.db_role_for_connection(data[:connection]).to_s.capitalize
          end

          detail
        end

        override :summary
        def summary
          if ::Gitlab::Database::LoadBalancing.enable?
            detail_store.each_with_object(super) do |item, count|
              count[item[:db_role]] ||= 0
              count[item[:db_role]] += 1
            end
          else
            super
          end
        end
      end
    end
  end
end

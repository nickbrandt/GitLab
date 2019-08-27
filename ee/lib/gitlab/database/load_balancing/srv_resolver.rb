# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SrvResolver
        include Gitlab::Utils::StrongMemoize

        attr_reader :resolver, :additional

        def initialize(resolver, additional)
          @resolver = resolver
          @additional = additional
        end

        def address_for(host)
          addresses_from_additional[host] || resolve_host(host)
        end

        private

        def addresses_from_additional
          strong_memoize(:addresses_from_additional) do
            additional.each_with_object({}) do |rr, h|
              h[rr.name] = rr.address if rr.is_a?(Net::DNS::RR::A) || rr.is_a?(Net::DNS::RR::AAAA)
            end
          end
        end

        def resolve_host(host)
          record = resolver.search(host, Net::DNS::ANY).answer.find do |rr|
            rr.is_a?(Net::DNS::RR::A) || rr.is_a?(Net::DNS::RR::AAAA)
          end

          record&.address
        end
      end
    end
  end
end

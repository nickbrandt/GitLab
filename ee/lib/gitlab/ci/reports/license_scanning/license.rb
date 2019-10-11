# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module LicenseScanning
        class License
          attr_reader :id, :name, :url

          delegate :count, to: :dependencies

          def initialize(id:, name:, url:)
            @id = 'unknown' == id ? nil : id
            @name = name
            @url = url
            @dependencies = Set.new
          end

          def canonical_id
            id || name&.downcase
          end

          def hash
            canonical_id.hash
          end

          def add_dependency(name)
            @dependencies.add(::Gitlab::Ci::Reports::LicenseScanning::Dependency.new(name))
          end

          def dependencies
            @dependencies.to_a
          end

          def eql?(other)
            super(other) ||
              (id && other.id && id.eql?(other.id)) ||
              (name && other.name && name.casecmp?(other.name))
          end
        end
      end
    end
  end
end

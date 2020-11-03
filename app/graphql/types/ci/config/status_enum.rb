# frozen_string_literal: true

module Types
  module Ci
    module Config
      class StatusEnum < BaseEnum
        graphql_name 'CiConfigStatus'
        description 'Values for YAML processor result'

        value 'VALID', 'Valid `gitlab-ci.yml`'
        value 'INVALID', 'Invalid `gitlab-ci.yml`'
      end
    end
  end
end

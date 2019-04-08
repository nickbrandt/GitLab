# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_locations_sast, class: ::Gitlab::Ci::Reports::Security::Locations::Sast do
    file_path 'maven/src/main/java/com/gitlab/security_products/tests/App.java'
    start_line 29
    end_line 31
    class_name 'com.gitlab.security_products.tests.App'
    method_name 'insecureCypher'

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Locations::Sast.new(attributes)
    end
  end
end

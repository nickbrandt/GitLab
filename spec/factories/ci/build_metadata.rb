# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_metadata, class: Ci::BuildMetadata do
    ci_build
    project

    %i[sast codequality dependency_scanning container_scanning dast performance license_management].each do |report_type|
      trait report_type do
        config_options { {
          artifacts: {
            reports: {
              "#{report_type}": "#{report_type}.json"
            }
          }
        } }
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :daily_code_coverage do
    ref { 'test_branch' }
    name { 'test_coverage_job' }
    coverage { 77 }
    date { Time.zone.now.to_date }

    after(:build) do |dcc|
      pipeline = create(:ci_pipeline)

      dcc.project_id = pipeline.project_id unless dcc.project_id
      dcc.last_pipeline_id = pipeline.id unless dcc.last_pipeline_id
    end
  end
end

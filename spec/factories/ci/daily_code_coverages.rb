# frozen_string_literal: true

FactoryBot.define do
  factory :ci_daily_code_coverage, class: 'Ci::DailyCodeCoverage' do
    ref { 'test_branch' }
    name { 'test_coverage_job' }
    coverage { 77 }
    date { Time.zone.now.to_date }

    after(:build) do |dcc|
      build = create(:ci_build)

      dcc.project_id = build.project_id unless dcc.project_id
      dcc.last_build_id = build.id unless dcc.last_build_id
    end
  end
end

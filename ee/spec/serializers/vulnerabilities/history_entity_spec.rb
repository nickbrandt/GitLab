# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoryEntity do
  let(:project) { create(:project) }
  let(:time) { Time.zone.parse('2018-11-10') }

  let(:entity) do
    travel_to(Time.zone.parse('2018-11-15')) do
      described_class.represent(project.vulnerability_findings.count_by_day_and_severity(3.months))
    end
  end

  before do
    travel_to(time) do
      pipeline_1 = create(:ci_pipeline, :success, project: project)

      create_list(:vulnerabilities_occurrence, 2,
        pipelines: [pipeline_1], project: project, report_type: :sast, severity: :high)

      create_list(:vulnerabilities_occurrence, 1,
        pipelines: [pipeline_1], project: project, report_type: :dependency_scanning, severity: :low)
    end
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject[:total]).to eq({ time.to_date => 3 })
      expect(subject[:high]).to eq({ time.to_date => 2 })
      expect(subject[:low]).to eq({ time.to_date => 1 })
    end
  end
end

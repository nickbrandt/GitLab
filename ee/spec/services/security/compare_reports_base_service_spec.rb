# frozen_string_literal: true

require 'spec_helper'

describe Security::CompareReportsBaseService, '#execute' do
  let(:occurrence_1) { create(:ci_reports_security_occurrence, :dynamic) }
  let(:occurrence_2) { create(:ci_reports_security_occurrence, :dynamic) }
  let(:occurrence_3) { create(:ci_reports_security_occurrence, :dynamic) }
  let(:base_report) { create(:ci_reports_security_report, occurrences: [occurrence_1, occurrence_2]) }
  let(:head_report) { create(:ci_reports_security_report, occurrences: [occurrence_2, occurrence_3]) }

  subject { described_class.new(base_report, head_report).execute }

  it 'exposes added occurrences' do
    expect(subject.added).to contain_exactly(occurrence_3)
  end

  it 'exposes existing occurrences' do
    expect(subject.existing).to contain_exactly(occurrence_2)
  end

  it 'exposes fixed occurrences' do
    expect(subject.fixed).to contain_exactly(occurrence_1)
  end
end

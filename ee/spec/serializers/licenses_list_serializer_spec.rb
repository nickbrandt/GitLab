# frozen_string_literal: true

require 'spec_helper'

describe LicensesListSerializer do
  describe '#to_json' do
    subject do
      described_class.new(project: project, user: user)
        .represent(report.licenses, build: ci_build)
        .to_json
    end

    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:ci_build) { create(:ee_ci_build, :success) }
    let(:report) { build(:ci_reports_license_scanning_report, :mit) }

    before do
      project.add_guest(user)
    end

    it { is_expected.to match_schema('licenses_list', dir: 'ee') }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::TestReport do
  describe 'associations' do
    subject { build(:test_report) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:requirement) }
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:build) }
  end

  describe 'validations' do
    subject { build(:test_report) }

    it { is_expected.to validate_presence_of(:requirement) }
    it { is_expected.to validate_presence_of(:state) }

    describe 'pipeline reference' do
      it { is_expected.to be_valid }

      it 'is valid to if both build and pipeline are nil' do
        subject.build = nil
        subject.pipeline_id = nil

        expect(subject).to be_valid
      end

      it 'is invalid if build references a different pipeline' do
        subject.pipeline_id = nil

        expect(subject).to be_invalid
      end
    end
  end

  describe 'scopes' do
    describe 'for_user_build' do
      it "returns only test reports matching build's user and pipeline" do
        user = create(:user)
        build = create(:ci_build)
        report1 = create(:test_report, author: user, build: build)
        create(:test_report, author: user)
        create(:test_report, build: build)

        expect(described_class.for_user_build(user.id, build.id)).to match_array([report1])
      end
    end
  end

  describe '.persist_all_requirement_reports_as_passed' do
    let_it_be(:project) { create(:project) }
    let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project) }

    subject { described_class.persist_all_requirement_reports_as_passed(build) }

    it 'creates test report with passed status for each open requirement' do
      requirement = create(:requirement, state: :opened, project: project)
      create(:requirement, state: :opened)
      create(:requirement, state: :archived, project: project)

      expect { subject }.to change { RequirementsManagement::TestReport.count }.by(1)

      reports = RequirementsManagement::TestReport.where(pipeline: build.pipeline)
      expect(reports.size).to eq(1)
      expect(reports.first).to have_attributes(
        requirement: requirement,
        author: build.user,
        state: 'passed'
      )
    end
  end
end

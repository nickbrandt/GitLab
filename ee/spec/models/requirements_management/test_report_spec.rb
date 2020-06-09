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

  describe '.persist_requirement_reports' do
    let_it_be(:project) { create(:project) }
    let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project) }

    subject { described_class.persist_requirement_reports(build, ci_report) }

    context 'if the CI report contains no entries' do
      let(:ci_report) { Gitlab::Ci::Reports::RequirementsManagement::Report.new }

      it 'does not create any test reports' do
        expect { subject }.not_to change { RequirementsManagement::TestReport.count }
      end
    end

    context 'if the CI report contains some entries' do
      context 'and the entries are valid' do
        let(:ci_report) do
          Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
            report.add_requirement('requirement_iid1', 'passed')
            report.add_requirement('requirement_iid2', 'failed')
            report.add_requirement('requirement_iid3', 'passed')
          end
        end

        it 'creates test report with expected status for each open requirement' do
          requirement1 = create(:requirement, state: :opened, project: project)
          requirement2 = create(:requirement, state: :opened, project: project)
          create(:requirement, state: :opened) # different project
          create(:requirement, state: :archived, project: project) # archived

          expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

          reports = RequirementsManagement::TestReport.where(pipeline: build.pipeline)
          expect(reports).to match_array([
            have_attributes(
              requirement: requirement1,
              author: build.user,
              state: 'passed'),
            have_attributes(requirement: requirement2,
            author: build.user,
            state: 'failed')
          ])
        end
      end

      context 'and the entries are not valid' do
        let(:ci_report) do
          Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
            report.add_requirement('requirement_iid0', 'passed')
            report.add_requirement('requirement_iid1', 'nonsense')
            report.add_requirement('requirement_iid2', nil)
          end
        end

        it 'creates test report with expected status for each open requirement' do
          # ignore requirement IIDs that appear in the test but are missing
          create(:requirement, state: :opened, project: project, iid: 1)
          create(:requirement, state: :opened, project: project, iid: 2)

          expect { subject }.not_to change { RequirementsManagement::TestReport.count }
        end
      end
    end
  end
end

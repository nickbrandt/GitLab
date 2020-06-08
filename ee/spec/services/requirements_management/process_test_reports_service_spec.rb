# frozen_string_literal: true

require 'spec_helper'

describe RequirementsManagement::ProcessTestReportsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:build) { create(:ee_ci_build, :requirements_report, project: project, user: user) }

  describe '#execute' do
    let_it_be(:requirement1) { create(:requirement, state: :opened, project: project) }
    let_it_be(:requirement2) { create(:requirement, state: :opened, project: project) }
    let_it_be(:requirement3) { create(:requirement, state: :archived, project: project) }

    subject { described_class.new(build).execute }

    before do
      stub_licensed_features(requirements: true)
    end

    context 'when user can create requirements test reports' do
      before do
        project.add_reporter(user)
      end

      it 'creates new test report for each open requirement' do
        expect(RequirementsManagement::TestReport).to receive(:persist_all_requirement_reports_as_passed).with(build).and_call_original

        expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)
      end

      it 'does not create test report for the same pipeline and user twice' do
        expect { subject }.to change { RequirementsManagement::TestReport.count }.by(2)

        expect { subject }.not_to change { RequirementsManagement::TestReport }
      end

      context 'when build does not contain any requirements report' do
        let(:build) { create(:ee_ci_build, project: project, user: user) }

        it 'does not create any test report' do
          expect { subject }.not_to change { RequirementsManagement::TestReport }
        end
      end
    end

    context 'when user is not allowed to create requirements test reports' do
      it 'raises an exception' do
        expect { subject }.to raise_exception(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end

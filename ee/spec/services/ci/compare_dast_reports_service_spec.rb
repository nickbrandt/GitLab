# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareDastReportsService do
  let(:current_user) { project.users.take }
  let(:service) { described_class.new(project, current_user) }
  let(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(container_scanning: true, dast: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has DAST reports containing some vulnerabilities' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_dast_report, project: project) }

      it 'reports the new vulnerabilities, while not changing the counts of existing and fixed vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(20)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have DAST reports containing vulnerabilities' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_dast_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_dast_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'populates fields based on current_user' do
        payload = subject[:data]['fixed'].first

        expect(payload).not_to be_empty
        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_merge_request_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_dismissal_path']).not_to be_empty
        expect(payload['create_vulnerability_feedback_issue_path']).not_to be_empty
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].last['identifiers']).to include(a_hash_including('name' => 'CWE-201'))
      end

      it 'reports existing DAST vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(1)
        expect(subject[:data]['existing'].last['identifiers']).to include(a_hash_including('name' => 'CWE-120'))
      end

      it 'reports fixed DAST vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(19)
        expect(subject[:data]['fixed']).to include(
          a_hash_including(
            {
              'identifiers' => a_collection_including(
                a_hash_including(
                  "name" => "CWE-352"
                )
              )
            })
        )
      end
    end
  end
end

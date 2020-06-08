# frozen_string_literal: true

require 'spec_helper'

describe Mutations::Pipelines::RunDastScan do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_path) { project.full_path }
  let(:target_url) { FFaker::Internet.uri(:https) }
  let(:branch) { SecureRandom.hex }
  let(:scan_type) { Types::DastScanTypeEnum.enum[:passive] }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        branch: branch,
        project_path: project_path,
        target_url: target_url,
        scan_type: scan_type
      )
    end

    context 'when on demand scan feature is not enabled' do
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when on demand scan feature is enabled' do
      before do
        stub_feature_flags(security_on_demand_scans_feature_flag: true)
      end

      context 'when the project does not exist' do
        let(:project_path) { SecureRandom.hex }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user does not have permission to run a dast scan' do
        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it 'has no errors' do
          expect(subject[:errors]).to be_empty
        end

        it 'returns a pipeline_url containing the correct path' do
          actual_url = subject[:pipeline_url]
          pipeline = Ci::Pipeline.last
          expected_url = Rails.application.routes.url_helpers.project_pipeline_url(
            project,
            pipeline
          )
          expect(actual_url).to eq(expected_url)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryBuildOnFailureService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, :detached_merge_request_pipeline) }
    let_it_be(:job) { create(:ci_build, project: project, pipeline: pipeline, status: :failed) }

    subject(:execute) { described_class.new(job).execute }

    context 'when retry is allowed' do
      before do
        allow(job).to receive(:auto_retry_allowed?).and_return(true)
      end

      it 'retries the build' do
        expect(Ci::Build).to receive(:retry).with(job, job.user)

        execute
      end

      context 'when retry raises AccessDeniedError' do
        before do
          allow(Ci::Build).to receive(:retry).and_raise(Gitlab::Access::AccessDeniedError)
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error)

          execute
        end
      end
    end

    context 'when retry is not allowed' do
      before do
        allow(job).to receive(:auto_retry_allowed?).and_return(false)
      end

      it 'does not retry the build' do
        expect(Ci::Build).not_to receive(:retry).with(job, job.user)

        execute
      end
    end
  end
end

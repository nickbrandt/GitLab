# frozen_string_literal: true

require 'spec_helper'

describe ::Ci::DestroyPipelineService do
  let(:project) { create(:project) }
  let!(:pipeline) { create(:ci_pipeline, project: project) }

  subject { described_class.new(project, user).execute(pipeline) }

  context 'user is owner' do
    let(:user) { project.owner }

    it 'destroys the pipeline' do
      subject

      expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when audit events is enabled' do
      before do
        stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
      end

      it 'logs an audit event' do
        expect { subject }.to change { SecurityEvent.count }.by(1)

        event = SecurityEvent.first
        expect(event.entity_type).to eq('Ci::Pipeline')
        expect(event.entity_id).to eq(pipeline.id)
        expect(event.details[:custom_message]).to eq('Destroyed pipeline')
      end
    end

    context 'when the pipeline has jobs' do
      let!(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'destroys associated jobs' do
        subject

        expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys associated stages' do
        stages = pipeline.stages

        subject

        expect(stages).to all(raise_error(ActiveRecord::RecordNotFound))
      end

      context 'when job has artifacts' do
        let!(:artifact) { create(:ci_job_artifact, :archive, job: build) }

        it 'destroys associated artifacts' do
          subject

          expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  context 'user is not owner' do
    let(:user) { create(:user) }

    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end

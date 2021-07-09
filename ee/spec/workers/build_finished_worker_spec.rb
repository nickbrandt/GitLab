# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildFinishedWorker do
  let(:ci_runner) { create(:ci_runner) }
  let(:build) { create(:ee_ci_build, :success, runner: ci_runner) }
  let(:project) { build.project }
  let(:namespace) { project.shared_runners_limit_namespace }

  subject do
    described_class.new.perform(build.id)
  end

  def namespace_stats
    namespace.namespace_statistics || namespace.create_namespace_statistics
  end

  def project_stats
    project.statistics || project.create_statistics(namespace: project.namespace)
  end

  describe '#perform' do
    context 'when on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        allow_any_instance_of(EE::Project).to receive(:shared_runners_minutes_limit_enabled?).and_return(true)
      end

      context 'when cancel_pipelines_prior_to_destroy is disabled' do
        before do
          stub_feature_flags(cancel_pipelines_prior_to_destroy: false)
        end

        it 'updates the project stats' do
          expect { subject }.to change { project_stats.reload.shared_runners_seconds }
        end

        it 'updates the namespace stats' do
          expect { subject }.to change { namespace_stats.reload.shared_runners_seconds }
        end

        it 'notifies the owners of Groups' do
          namespace.update_attribute(:shared_runners_minutes_limit, 2000)
          namespace_stats.update_attribute(:shared_runners_seconds, 2100 * 60)

          expect(CiMinutesUsageMailer).to receive(:notify).once.with(namespace, [namespace.owner.email]).and_return(spy)

          subject
        end
      end
    end

    context 'when not on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not notify the owners of Groups' do
        expect(::Ci::Minutes::EmailNotificationService).not_to receive(:new)

        subject
      end
    end

    it 'does not schedule processing of requirement reports by default' do
      expect(RequirementsManagement::ProcessRequirementsReportsWorker).not_to receive(:perform_async)

      subject
    end

    it 'schedules processing of requirement reports if project has requirements' do
      create(:requirement, project: project)

      expect(RequirementsManagement::ProcessRequirementsReportsWorker).to receive(:perform_async)

      subject
    end

    context 'when token revocation is disabled' do
      before do
        allow_next_instance_of(described_class) do |build_finished_worker|
          allow(build_finished_worker).to receive(:revoke_secret_detection_token?) { false }
        end
      end

      it 'does not scan security reports for token revocation' do
        expect(ScanSecurityReportSecretsWorker).not_to receive(:perform_async)

        subject
      end
    end
  end
end

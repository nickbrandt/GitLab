# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoring::Project::CreateService do
  describe '#execute' do
    let(:prometheus_settings) do
      OpenStruct.new(
        enable: true,
        listen_address: 'localhost:9090'
      )
    end

    let(:result) { subject.execute }
    let(:project) { result[:project] }

    let!(:user) { create(:user, :admin) }

    before do
      allow(Gitlab.config).to receive(:prometheus).and_return(prometheus_settings)

      allow(ApplicationSetting)
        .to receive(:current)
        .and_return(
          ApplicationSetting.build_from_defaults(allow_local_requests_from_hooks_and_services: true)
        )
    end

    context 'with license' do
      before do
        stub_licensed_features(prometheus_alerts: true)
      end

      it 'generates a token' do
        expect(project.alerting_setting.token).not_to eq(nil)
      end

      context 'when project update fails' do
        let(:project_update_service) { ::Projects::UpdateService.new(nil) }

        before do
          expect_next_instance_of(::Projects::UpdateService) do |project_update_service|
            expect(project_update_service).to receive(:execute)
              .and_return({ status: :error, message: 'Update failed' })
          end
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq({
            status: :error,
            failed_step: :setup_alertmanager,
            message: 'Could not update alertmanager settings'
          })
        end
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(prometheus_alerts: false)
      end

      it 'does not fail' do
        expect(project.persisted?).to eq(true)
        expect(project.alerting_setting).to eq(nil)
      end
    end
  end
end

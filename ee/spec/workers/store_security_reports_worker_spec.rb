# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StoreSecurityReportsWorker do
  let_it_be(:secret_detection_scan_1) { create(:security_scan, scan_type: :secret_detection) }
  let_it_be(:secret_detection_scan_2) { create(:security_scan, scan_type: :secret_detection) }
  let_it_be(:secret_detection_pipeline) { secret_detection_scan_2.pipeline }

  describe '#secret_detection_vulnerability_found?' do
    before do
      create(:vulnerabilities_finding, :with_secret_detection, pipelines: [secret_detection_pipeline], project: secret_detection_pipeline.project)
    end

    specify { expect(described_class.new.send(:secret_detection_vulnerability_found?, secret_detection_pipeline)).to be(true) }
  end

  describe '#revoke_secret_detection_token?' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility, :token_revocation_enabled, :secret_detection_vulnerability_found) do
      booleans = [true, true, false, false].permutation(2).to_a.uniq
      [:public, :private, nil].flat_map do |vis|
        booleans.map { |bools| [vis, *bools] }
      end
    end

    with_them do
      let(:pipeline) { build(:ci_pipeline, project: build(:project, :repository, visibility)) if visibility }
      let(:expected_result) { [visibility, token_revocation_enabled, secret_detection_vulnerability_found] == [:public, true, true] }

      before do
        stub_application_setting(secret_detection_token_revocation_enabled: token_revocation_enabled)

        allow_next_instance_of(described_class) do |store_scans_worker|
          allow(store_scans_worker).to receive(:secret_detection_vulnerability_found?) { secret_detection_vulnerability_found }
        end
      end

      specify { expect(described_class.new.send(:revoke_secret_detection_token?, pipeline)).to eql(expected_result) }
    end
  end

  describe '#perform' do
    let(:group)   { create(:group) }
    let(:project) { create(:project, namespace: group) }
    let(:pipeline) { create(:ci_pipeline, ref: 'master', project: project) }

    before do
      allow(Ci::Pipeline).to receive(:find).with(pipeline.id) { pipeline }

      allow(::ScanSecurityReportSecretsWorker).to receive(:perform_async).and_return(nil)
      allow_next_instance_of(described_class) do |store_scans_worker|
        allow(store_scans_worker).to receive(:revoke_secret_detection_token?) { true }
      end
    end

    context 'when at least one security report feature is enabled' do
      where(report_type: [:sast, :dast, :dependency_scanning, :container_scanning, :cluster_image_scanning])

      with_them do
        before do
          stub_licensed_features(report_type => true)
        end

        it 'executes StoreReportsService for given pipeline' do
          expect(Security::StoreReportsService).to receive(:new)
            .with(pipeline).once.and_call_original

          described_class.new.perform(pipeline.id)
        end

        it 'scans security reports for token revocation' do
          expect(::ScanSecurityReportSecretsWorker).to receive(:perform_async)

          described_class.new.perform(pipeline.id)
        end
      end
    end

    context "when security reports feature is not available" do
      let(:default_branch) { pipeline.ref }

      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end

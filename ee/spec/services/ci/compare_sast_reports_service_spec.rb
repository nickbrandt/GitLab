# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareSastReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(container_scanning: true)
    stub_licensed_features(sast: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has sast reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(33)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have sast reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added']).to include(a_hash_including('compare_key' => 'c/subdir/utils.c:b466873101951fe96e1332f6728eb7010acbbd5dfc3b65d7d53571d091a06d9e:CWE-119!/CWE-120'))
      end

      it 'reports existing sast vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(29)
      end

      it 'reports fixed sast vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(4)
        compare_keys = subject[:data]['fixed'].map { |t| t['compare_key'] }
        expected_keys = ['c/subdir/utils.c:b466873101951fe96e1332f6728eb7010acbbd5dfc3b65d7d53571d091a06d9e:CWE-119!/CWE-120', 'c/subdir/utils.c:bab681140fcc8fc3085b6bba74081b44ea145c1c98b5e70cf19ace2417d30770:CWE-362', 'cplusplus/src/hello.cpp:c8c6dd0afdae6814194cf0930b719f757ab7b379cf8f261e7f4f9f2f323a818a:CWE-119!/CWE-120', 'cplusplus/src/hello.cpp:331c04062c4fe0c7c486f66f59e82ad146ab33cdd76ae757ca41f392d568cbd0:CWE-120']
        expect(compare_keys - expected_keys).to eq([])
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::AdaptiveBuildFinder do
  let(:pipeline) { create(:ci_pipeline) }
  let(:sast_build) { create(:ee_ci_build, :sast, pipeline: pipeline) }
  let(:dast_build) { create(:ee_ci_build, :dast, pipeline: pipeline) }
  let(:secret_detection_build) { create(:ee_ci_build, :secret_detection, pipeline: pipeline) }
  let(:report_types) { %w(sast dast secret_detection) }
  let(:severities) { %w(critical) }
  let(:confidence_levels) { %w(confirmed) }
  let(:params) { { report_types: report_types, severities: severities, confidence_levels: confidence_levels} }
  let(:service_object) { described_class.new(pipeline, params.merge(page, per_page)) }

  describe '#execute' do
    subject(:locate_builds) { service_object.execute }

    before do
      create(:security_scan, build: sast_build, severity_stats: { critical: { confirmed: 35, experimental: 23 } })
      create(:security_scan, build: dast_build, severity_stats: { critical: { confirmed: 3 }, medium: { confirmed: 12 } })
      create(:security_scan, build: secret_detection_build, severity_stats: { critical: { confirmed: 5 }, low: { confirmed: 21 } })
    end

    context 'when the `page` is not provided' do
      let(:page) { {} }

      context 'when the `per_page` is not provided' do
        let(:per_page) { {} }

        it 'returns the build(s) for 20 findings on first page' do
          expect(locate_builds).to match_array([sast_build])
        end
      end

      context 'when the `per_page` is provided' do
        let(:per_page) { { per_page: 36 } }

        it 'returns the build(s) for given amount of findings on first page' do
          expect(locate_builds).to match_array([sast_build, dast_build])
        end
      end
    end

    context 'when the page is provided' do
      let(:page) { { page: 2 } }

      context 'when the `per_page` is not provided' do
        let(:per_page) { {} }

        it 'returns the build(s) for 20 findings on given page' do
          expect(locate_builds).to match_array([sast_build, dast_build, secret_detection_build])
        end
      end

      context 'when the `per_page` is provided' do
        let(:per_page) { { per_page: 35 } }

        it 'returns the build(s) for given amount of findings on given page' do
          expect(locate_builds).to match_array([sast_build, dast_build, secret_detection_build])
        end
      end
    end
  end
end

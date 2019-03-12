# frozen_string_literal: true

require 'spec_helper'

describe EE::PrometheusAdapter, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }

  let(:described_class) do
    Class.new do
      include PrometheusAdapter
    end
  end

  let(:environment_query) { Gitlab::Prometheus::Queries::EnvironmentQuery }

  describe 'validate_query' do
    let(:environment) { build_stubbed(:environment, slug: 'env-slug') }
    let(:validation_query) { Gitlab::Prometheus::Queries::ValidateQuery.name }
    let(:query) { 'avg(response)' }
    let(:validation_respone) { { data: { valid: true } } }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'with valid data' do
      subject { service.query(:validate, query) }

      before do
        stub_reactive_cache(service, validation_respone, validation_query, query)
      end

      it 'returns query data' do
        is_expected.to eq(query: { valid: true })
      end
    end
  end
end

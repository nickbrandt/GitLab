# frozen_string_literal: true

require 'spec_helper'

describe Security::WafAnomalySummaryService do
  let(:environment) { create(:environment, :with_review_app) }
  let!(:cluster) do
    create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [environment.project])
  end

  let(:es_client) { double(Elasticsearch::Client) }

  let(:nginx_response) do
    empty_response.deep_merge(
      "hits" => { "total" => 3 },
      "aggregations" => {
        "counts" => {
          "buckets" => [
            { "key_as_string" => "2020-02-14T23:00:00.000Z", "key" => 1575500400000, "doc_count" => 1 },
            { "key_as_string" => "2020-02-15T00:00:00.000Z", "key" => 1575504000000, "doc_count" => 0 },
            { "key_as_string" => "2020-02-15T01:00:00.000Z", "key" => 1575507600000, "doc_count" => 0 },
            { "key_as_string" => "2020-02-15T08:00:00.000Z", "key" => 1575532800000, "doc_count" => 2 }
          ]
        }
      }
    )
  end

  let(:empty_response) do
    {
      "took" => 40,
      "timed_out" => false,
      "_shards" => { "total" => 11, "successful" => 11, "skipped" => 0, "failed" => 0 },
      "hits" => { "total" => 0, "max_score" => 0.0, "hits" => [] },
      "aggregations" => {
        "counts" => {
          "buckets" => []
        }
      },
      "status" => 200
    }
  end

  subject { described_class.new(environment: environment) }

  describe '#execute' do
    context 'without elastic_stack' do
      it 'returns no results' do
        expect(subject.execute).to be_nil
      end
    end

    context 'with default histogram' do
      before do
        allow(es_client).to receive(:msearch) do
          { "responses" => [nginx_results, modsec_results] }
        end

        allow(environment.deployment_platform.cluster).to receive_message_chain(
          :application_elastic_stack, :elasticsearch_client
        ) { es_client }
      end

      context 'no requests' do
        let(:nginx_results) { empty_response }
        let(:modsec_results) { empty_response }

        it 'returns results' do
          results = subject.execute

          expect(results.fetch(:status)).to eq :success
          expect(results.fetch(:interval)).to eq 'day'
          expect(results.fetch(:total_traffic)).to eq 0
          expect(results.fetch(:anomalous_traffic)).to eq 0.0
        end
      end

      context 'no violations' do
        let(:nginx_results) { nginx_response }
        let(:modsec_results) { empty_response }

        it 'returns results' do
          results = subject.execute

          expect(results.fetch(:status)).to eq :success
          expect(results.fetch(:interval)).to eq 'day'
          expect(results.fetch(:total_traffic)).to eq 3
          expect(results.fetch(:anomalous_traffic)).to eq 0.0
        end
      end
    end

    context 'with time window' do
      it 'passes time frame to ElasticSearch' do
        from = 1.day.ago
        to = Time.now

        subject = described_class.new(
          environment: environment,
          from: from,
          to: to
        )

        allow(subject).to receive(:elasticsearch_client) { es_client }

        expect(es_client).to receive(:msearch).with(
          body: array_including(
            hash_including(
              query: hash_including(
                bool: hash_including(
                  must: array_including(
                    hash_including(
                      range: hash_including(
                        '@timestamp' => {
                          gte: from,
                          lte: to
                        }
                      )
                    )
                  )
                )
              )
            )
          )
        ).and_return({ 'responses' => [{}] })

        subject.execute
      end
    end

    context 'with interval' do
      it 'passes interval to ElasticSearch' do
        interval = 'hour'

        subject = described_class.new(
          environment: environment,
          interval: interval
        )

        allow(subject).to receive(:elasticsearch_client) { es_client }

        expect(es_client).to receive(:msearch).with(
          body: array_including(
            hash_including(
              aggs: hash_including(
                counts: hash_including(
                  date_histogram: hash_including(
                    interval: interval
                  )
                )
              )
            )
          )
        ).and_return({ 'responses' => [{}] })

        subject.execute
      end
    end
  end
end

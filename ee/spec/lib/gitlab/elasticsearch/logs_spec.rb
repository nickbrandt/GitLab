# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elasticsearch::Logs do
  let(:client) { Elasticsearch::Transport::Client }

  let(:es_message_1) { "10.8.2.1 - - [25/Oct/2019:08:03:22 UTC] \"GET / HTTP/1.1\" 200 13" }
  let(:es_message_2) { "10.8.2.1 - - [27/Oct/2019:23:49:54 UTC] \"GET / HTTP/1.1\" 200 13" }
  let(:es_message_3) { "10.8.2.1 - - [04/Nov/2019:23:09:24 UTC] \"GET / HTTP/1.1\" 200 13" }
  let(:es_message_4) { "- -\u003e /" }

  let(:es_response) { JSON.parse(fixture_file('lib/elasticsearch/logs_response.json', dir: 'ee')) }

  subject { described_class.new(client) }

  let(:namespace) { "autodevops-deploy-9-production" }
  let(:pod_name) { "production-6866bc8974-m4sk4" }
  let(:container_name) { "auto-deploy-app" }

  let(:body) do
    {
      query: {
        bool: {
            must: [
                {
                    match_phrase: {
                        "kubernetes.pod.name" => {
                            query: pod_name
                        }
                    }
                },
                {
                    match_phrase: {
                        "kubernetes.namespace" => {
                            query: namespace
                        }
                    }
                }
            ]
        }
      },
      sort: [
        {
            :@timestamp => {
                order: :desc
            }
        },
        {
            offset: {
                order: :desc
            }
        }
      ],
      _source: [
          "message"
      ],
      size: 500
    }
  end

  let(:body_with_container) do
    {
      query: {
        bool: {
            must: [
                {
                    match_phrase: {
                        "kubernetes.pod.name" => {
                            query: pod_name
                        }
                    }
                },
                {
                    match_phrase: {
                        "kubernetes.namespace" => {
                            query: namespace
                        }
                    }
                },
                {
                    match_phrase: {
                        "kubernetes.container.name" => {
                            query: container_name
                        }
                    }
                }
            ]
        }
      },
      sort: [
        {
            :@timestamp => {
                order: :desc
            }
        },
        {
            offset: {
                order: :desc
            }
        }
      ],
      _source: [
          "message"
      ],
      size: 500
    }
  end

  describe '#pod_logs' do
    it 'returns the logs as an array' do
      expect(client).to receive(:search).with(body: body).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name)
      expect(result).to eq([es_message_4, es_message_3, es_message_2, es_message_1])
    end

    it 'can further filter the logs by container name' do
      expect(client).to receive(:search).with(body: body_with_container).and_return(es_response)

      result = subject.pod_logs(namespace, pod_name, container_name)
      expect(result).to eq([es_message_4, es_message_3, es_message_2, es_message_1])
    end
  end
end

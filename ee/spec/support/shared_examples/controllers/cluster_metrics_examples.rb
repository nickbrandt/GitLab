# frozen_string_literal: true

require 'spec_helper'

shared_examples 'cluster metrics' do
  include AccessMatchersForController

  describe 'GET #metrics' do
    before do
      allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
    end

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        clusterable.add_maintainer(user)
        sign_in(user)
      end

      context 'can query Prometheus' do
        let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: true, query: nil) }

        it 'queries cluster metrics' do
          go

          expect(prometheus_adapter).to have_received(:query).with(:cluster)
        end

        context 'when response has content' do
          let(:query_response) { { non_empty: :response } }

          before do
            allow(prometheus_adapter).to receive(:query).and_return(query_response)
          end

          it 'returns prometheus query response' do
            go

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to eq(query_response.to_json)
          end
        end

        context 'when response has no content' do
          let(:query_response) { nil }

          before do
            allow(prometheus_adapter).to receive(:query).and_return(query_response)
          end

          it 'returns prometheus query response' do
            go

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end
      end

      context 'without Prometheus' do
        let(:prometheus_adapter) { nil }

        it 'returns not found' do
          go

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'cannot query Prometheus' do
        let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: false) }

        it 'returns not found' do
          go

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'security' do
      let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: true, query: nil) }

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(clusterable) }
      it { expect { go }.to be_allowed_for(:maintainer).of(clusterable) }
      it { expect { go }.to be_denied_for(:developer).of(clusterable) }
      it { expect { go }.to be_denied_for(:reporter).of(clusterable) }
      it { expect { go }.to be_denied_for(:guest).of(clusterable) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    private

    def go
      get :metrics, params: metrics_params, format: :json
    end
  end
end

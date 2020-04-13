# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::NetworkPoliciesController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:environment) { create(:environment, :with_review_app, project: project) }

  let_it_be(:action_params) { { project_id: project, namespace_id: project.namespace, environment_id: environment } }

  describe 'GET #summary' do
    subject { get :summary, params: action_params, format: :json }

    let_it_be(:kubernetes_namespace) { environment.deployment_namespace }

    before do
      stub_licensed_features(threat_monitoring: true)

      sign_in(user)
    end

    context 'with authorized user' do
      before do
        group.add_developer(user)
      end

      context 'with prometheus configured' do
        let(:adapter) { double("configured?" => true, "can_query?" => true) }

        before do
          allow_next_instance_of(Gitlab::Prometheus::Adapter) do |instance|
            allow(instance).to receive(:prometheus_adapter) { adapter }
          end
        end

        it 'returns network policies summary' do
          Timecop.freeze do
            expect(adapter).to(
              receive(:query)
                .with(:packet_flow, kubernetes_namespace, interval: "minute", from: 1.hour.ago, to: Time.now)
                .and_return({ success: true, data: { ops_rate: [[Time.at(0).to_i, 10]], ops_total: 10 } })
            )
            subject
          end

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['ops_total']).to equal(10)
          expect(json_response['ops_rate']).to eq([[0, 10]])
        end

        context 'with additional parameters' do
          let(:action_params) do
            {
              project_id: project, namespace_id: project.namespace, environment_id: environment,
              interval:  "day", from: Time.at(0), to: Time.at(100)
            }
          end

          it 'queries with requested arguments' do
            expect(adapter).to(
              receive(:query)
                .with(:packet_flow, kubernetes_namespace, interval: "day", from: Time.at(0), to: Time.at(100))
                .and_return({ success: true, data: {} })
            )
            subject
          end
        end

        context 'with invalid Time range' do
          let(:action_params) do
            {
              project_id: project, namespace_id: project.namespace, environment_id: environment,
              from: "not a time", to: "not a time"
            }
          end

          it 'queries with default arguments' do
            Timecop.freeze do
              expect(adapter).to(
                receive(:query)
                  .with(:packet_flow, kubernetes_namespace, interval: "minute", from: 1.hour.ago, to: Time.now)
                  .and_return({ success: true, data: {} })
              )
              subject
            end
          end
        end

        context 'with nil results' do
          it 'returns network policies summary' do
            allow(adapter).to receive(:query).and_return(nil)
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'without prometheus configured' do
        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'sets a polling interval header' do
        subject

        expect(response.headers['Poll-Interval']).to eq('5000')
      end
    end

    context 'with unauthorized user' do
      it 'returns unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end

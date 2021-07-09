# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::CreateService do
  subject(:service) { described_class.new(container: project, current_user: user, params: params) }

  let_it_be(:user) { create(:user) }

  let(:cluster_agent) { create(:cluster_agent) }
  let(:project) { cluster_agent.project }
  let(:params) { { agent_id: cluster_agent.id, description: 'token description', name: 'token name' } }

  before do
    stub_licensed_features(cluster_agents: false)
  end

  describe '#execute' do
    subject { service.execute }

    context 'without premium plan' do
      it 'does not create a new token' do
        expect { subject }.not_to change(Clusters::AgentToken, :count)
      end

      it 'returns missing license error' do
        expect(subject.status).to eq(:error)
        expect(subject.message).to eq('This feature is only available for premium plans')
      end

      context 'with premium plan' do
        before do
          stub_licensed_features(cluster_agents: true)
        end

        it 'does not create a new token due to user permissions' do
          expect { subject }.not_to change(::Clusters::AgentToken, :count)
        end

        it 'returns permission errors', :aggregate_failures do
          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('User has insufficient permissions to create a token for this project')
        end

        context 'with user permissions' do
          before do
            project.add_maintainer(user)
          end

          it 'creates a new token' do
            expect { subject }.to change { ::Clusters::AgentToken.count }.by(1)
          end

          it 'returns success status', :aggregate_failures do
            expect(subject.status).to eq(:success)
            expect(subject.message).to be_nil
          end

          it 'returns token information', :aggregate_failures do
            token = subject.payload[:token]

            expect(subject.payload[:secret]).not_to be_nil

            expect(token.created_by_user).to eq(user)
            expect(token.description).to eq(params[:description])
            expect(token.name).to eq(params[:name])
          end

          context 'when params are invalid' do
            let(:params) { { agent_id: 'bad_id' } }

            it 'does not create a new token' do
              expect { subject }.not_to change(::Clusters::AgentToken, :count)
            end

            it 'returns validation errors', :aggregate_failures do
              expect(subject.status).to eq(:error)
              expect(subject.message).to eq(["Agent must exist", "Name can't be blank"])
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentsResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Clusters::AgentType) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    let(:finder) { double(execute: :result) }
    let(:project) { create(:project) }

    subject { resolve(described_class, obj: project, ctx: { current_user: user }) }

    it 'calls the agents finder' do
      expect(::Clusters::AgentsFinder).to receive(:new)
        .with(project, user).and_return(finder)

      expect(subject).to eq(:result)
    end
  end
end

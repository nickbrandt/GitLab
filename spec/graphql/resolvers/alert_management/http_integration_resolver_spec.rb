# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AlertManagement::HttpIntegrationResolver do
  include GraphqlHelpers
  include ::Gitlab::Graphql::Laziness

  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:args) { { id: global_id_of(integration) } }

  subject { sync(resolve_http_integration(args: args)) }

  before do
    project.add_developer(developer)
    project.add_maintainer(maintainer)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::AlertManagement::HttpIntegrationType)
  end

  context 'when user does not have permission' do
    let(:current_user) { guest }

    it { is_expected.to be_nil }
  end

  context 'when user has developer permissions' do
    let(:current_user) { developer }

    it { is_expected.to be_nil }
  end

  context 'when user has maintainer permissions' do
    let(:current_user) { maintainer }

    it { is_expected.to eq(integration) }
  end

  def resolve_http_integration(args: {}, ctx: { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: ctx)
  end
end

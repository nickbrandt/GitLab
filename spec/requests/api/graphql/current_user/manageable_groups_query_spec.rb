# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query current user manageable groups' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
  let_it_be(:private_maintainer_group) { create(:group, :private, name: 'private maintainer', path: 'private-maintainer') }
  let_it_be(:public_developer_group) { create(:group, project_creation_level: nil, name: 'public developer', path: 'public-developer') }
  let_it_be(:public_maintainer_group) { create(:group, name: 'public maintainer', path: 'public-maintainer') }

  let(:group_arguments) { {} }

  let(:fields) do
    <<~QUERY
      nodes { id }
    QUERY
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('manageableGroups', group_arguments, fields))
  end

  before_all do
    guest_group.add_guest(user)
    private_maintainer_group.add_maintainer(user)
    public_developer_group.add_developer(user)
    public_maintainer_group.add_maintainer(user)
  end

  subject { graphql_data.dig('currentUser', 'manageableGroups', 'nodes') }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when user is logged in' do
    let(:current_user) { user }

    it_behaves_like 'a working graphql query'

    it { is_expected.to match_array(global_id_for_groups([private_maintainer_group, public_developer_group, public_maintainer_group])) }

    context 'when search is provided' do
      let(:group_arguments) { { search: 'maintainer' } }

      it { is_expected.to match_array(global_id_for_groups([private_maintainer_group, public_maintainer_group])) }
    end
  end

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query'
  end

  def global_id_for_groups(groups)
    groups.map { |group| { 'id' => group.to_global_id.to_s } }
  end
end

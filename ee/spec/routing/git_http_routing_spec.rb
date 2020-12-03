# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE git_http routing', :aggregate_failures do
  context 'Geo routing' do
    it_behaves_like 'git repository routes' do
      let_it_be(:container) { create(:project, :public, :empty_repo) }
      let(:repository_path) { "/-/push_from_secondary/node/#{container.full_path}.git" }
      let(:params) { { geo_node_id: 'node', repository_path: "#{container.full_path}.git" } }
    end
  end

  describe 'group wiki repositories' do
    include WikiHelpers

    let_it_be(:group) { create(:group, :public) }

    before do
      stub_group_wikis(true)
    end

    context 'in toplevel group' do
      it_behaves_like 'git repository routes' do
        let_it_be(:container) { create(:group_wiki, :empty_repo, group: group) }
      end
    end

    context 'in child group' do
      it_behaves_like 'git repository routes' do
        let_it_be(:container) { create(:group_wiki, :empty_repo, group: child) }
        let_it_be(:child) { create(:group, :public, parent: group) }
      end
    end

    it_behaves_like 'git repository routes with fallback for git-upload-pack' do
      let(:path) { '/-/push_from_secondary/node/gitlab-org/gitlab-test.git' }
      let(:container_path) { '/gitlab-org/gitlab-test' }
      let(:params) { { geo_node_id: 'node', repository_path: 'gitlab-org/gitlab-test.git' } }
    end
  end
end

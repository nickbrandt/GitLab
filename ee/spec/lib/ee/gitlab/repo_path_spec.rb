# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepoPath do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_redirect_route) { 'foo/bar/baz' }
  let_it_be(:group_redirect) { group.route.create_redirect(group_redirect_route) }

  describe '.parse' do
    it 'parses a full path of group wiki' do
      expect(described_class.parse(group.wiki.repository.full_path)).to eq([group, nil, Gitlab::GlRepository::WIKI, nil])
    end
  end

  describe '.find_routes_source' do
    let(:project) { create(:project) }

    context 'without premium license' do
      context 'project_path matches a project alias' do
        let(:project_alias) { create(:project_alias, project: project) }

        it 'does not return a project' do
          expect(described_class.find_routes_source(project_alias.name)).to eq([nil, nil])
        end
      end
    end

    context 'with premium license' do
      before do
        stub_licensed_features(project_aliases: true)
      end

      context 'project_path matches a project alias' do
        let(:project_alias) { create(:project_alias, project: project) }

        it 'returns the project' do
          expect(described_class.find_routes_source(project_alias.name)).to eq([project, nil])
        end
      end

      context 'project_path does not match a project alias' do
        context 'project path matches project full path' do
          it 'returns the project' do
            expect(described_class.find_routes_source(project.full_path)).to eq([project, nil])
          end
        end

        context 'project path does not match an existing project full path' do
          it 'returns nil' do
            expect(described_class.find_routes_source('some-project')).to eq([nil, nil])
          end
        end
      end
    end

    context 'when target is a group' do
      context 'when finding by canonical path' do
        it 'returns the group and nil' do
          expect(described_class.find_routes_source(group.full_path)).to eq([group, nil])
        end
      end

      context 'when finding via a redirect' do
        it 'returns the group and redirect path' do
          expect(described_class.find_routes_source(group_redirect.path)).to eq([group, group_redirect_route])
        end
      end
    end
  end
end

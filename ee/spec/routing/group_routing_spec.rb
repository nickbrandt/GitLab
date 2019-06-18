require 'spec_helper'

describe 'Group routing', "routing" do
  include RSpec::Rails::RoutingExampleGroup

  describe 'subgroup "boards"' do
    it 'shows group show page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq/boards', any_args).and_return(true)

      expect(get('/groups/gitlabhq/boards')).to route_to('groups#show', id: 'gitlabhq/boards')
    end

    it 'shows boards index page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/boards')).to route_to('groups/boards#index', group_id: 'gitlabhq')
    end
  end

  describe 'legacy redirection' do
    %w(analytics
       boards
       ldap
       ldap_group_links
       notification_setting
       audit_events
       pipeline_quota hooks).each do |legacy_reserved_path|
      describe legacy_reserved_path do
        it_behaves_like 'redirecting a legacy path',
                        "/groups/complex.group-namegit/#{legacy_reserved_path}",
                        "/groups/complex.group-namegit/-/#{legacy_reserved_path}" do
          let!(:parent) { create(:group, path: 'complex.group-namegit') }
          let(:resource) { create(:group, parent: parent, path: legacy_reserved_path) }
        end
      end
    end

    context 'multiple redirects' do
      include RSpec::Rails::RequestExampleGroup

      let!(:parent) { create(:group, path: 'complex.group-namegit') }

      it 'follows multiple redirects' do
        expect(get('/groups/complex.group-namegit/boards/issues'))
          .to redirect_to('/groups/complex.group-namegit/-/boards/issues')
      end

      it 'does not redirect when the nested group exists' do
        boards_group = create(:group, path: 'boards', parent: parent)
        create(:group, path: 'issues', parent: boards_group)

        expect(get('/groups/complex.group-namegit/boards/issues'))
          .to eq(200)
      end
    end
  end

  describe 'security' do
    it 'shows group dashboard' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/security/dashboard')).to route_to('groups/security/dashboard#show', group_id: 'gitlabhq')
    end

    it 'lists vulnerabilities' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/security/vulnerabilities')).to route_to('groups/security/vulnerabilities#index', group_id: 'gitlabhq')
    end

    it 'shows vulnerability summary' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/security/vulnerabilities/summary')).to route_to('groups/security/vulnerabilities#summary', group_id: 'gitlabhq')
    end

    it 'shows vulnerability history' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/security/vulnerabilities/history')).to route_to('groups/security/vulnerabilities#history', group_id: 'gitlabhq')
    end
  end

  describe 'dependency proxy for containers' do
    before do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)
    end

    context 'image name without namespace' do
      it 'routes to #manifest' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ruby/manifests/2.3.6'))
          .to route_to('groups/dependency_proxy_for_containers#manifest', group_id: 'gitlabhq', image: 'ruby', tag: '2.3.6')
      end

      it 'routes to #blob' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/ruby/blobs/abc12345'))
          .to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'ruby', sha: 'abc12345')
      end
    end

    context 'image name with namespace' do
      it 'routes to #manifest' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/foo/bar/manifests/2.3.6'))
          .to route_to('groups/dependency_proxy_for_containers#manifest', group_id: 'gitlabhq', image: 'foo/bar', tag: '2.3.6')
      end

      it 'routes to #blob' do
        expect(get('/v2/gitlabhq/dependency_proxy/containers/foo/bar/blobs/abc12345'))
          .to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'foo/bar', sha: 'abc12345')
      end
    end
  end
end

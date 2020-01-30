# frozen_string_literal: true

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

      it "does not route to #blob with an invalid sha" do
        expect(get("/v2/gitlabhq/dependency_proxy/containers/ruby/blobs/sha256:asdf1234%2f%2e%2e"))
          .not_to route_to(group_id: 'gitlabhq', image: 'ruby', sha: 'sha256:asdf1234%2f%2e%2e')
      end

      it "does not route to #blob with an invalid image" do
        expect(get("/v2/gitlabhq/dependency_proxy/containers/ru*by/blobs/abc12345"))
          .not_to route_to('groups/dependency_proxy_for_containers#blob', group_id: 'gitlabhq', image: 'ru*by', sha: 'abc12345')
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

  describe 'packages' do
    it 'routes to packages index page' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(get('/groups/gitlabhq/-/packages')).to route_to('groups/packages#index', group_id: 'gitlabhq')
    end
  end

  describe 'issues' do
    it 'routes post to #bulk_update' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(post('/groups/gitlabhq/-/issues/bulk_update')).to route_to('groups/issues#bulk_update', group_id: 'gitlabhq')
    end
  end

  describe 'merge_requests' do
    it 'routes post to #bulk_update' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(post('/groups/gitlabhq/-/merge_requests/bulk_update')).to route_to('groups/merge_requests#bulk_update', group_id: 'gitlabhq')
    end
  end

  describe 'epics' do
    it 'routes post to #bulk_update' do
      allow(Group).to receive(:find_by_full_path).with('gitlabhq', any_args).and_return(true)

      expect(post('/groups/gitlabhq/-/epics/bulk_update')).to route_to('groups/epics#bulk_update', group_id: 'gitlabhq')
    end
  end
end

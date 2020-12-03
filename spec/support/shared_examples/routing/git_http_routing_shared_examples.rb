# frozen_string_literal: true

RSpec.shared_examples 'git repository routes' do
  let(:repository_path) { "/#{container.full_path}.git" }
  let(:web_path) { container.web_url(only_path: true) }
  let(:params) { { repository_path: repository_path.delete_prefix('/') } }

  it 'routes Git endpoints' do
    expect(get("#{repository_path}/info/refs")).to route_to('repositories/git_http#info_refs', **params)
    expect(post("#{repository_path}/git-upload-pack")).to route_to('repositories/git_http#git_upload_pack', **params)
    expect(post("#{repository_path}/git-receive-pack")).to route_to('repositories/git_http#git_receive_pack', **params)
  end

  context 'requests to the toplevel repository path', type: :request do
    it 'redirects to the container' do
      expect(get("#{repository_path}?foo=bar&baz=qux")).to redirect_to("#{web_path}?foo=bar&baz=qux")
    end

    it 'only redirects when the format is .git' do
      expect(get(repository_path.delete_suffix('.git'))).not_to redirect_to(web_path)
      expect(get(repository_path.delete_suffix('.git') + '.json')).not_to redirect_to(web_path)
    end
  end

  context 'requests without .git format' do
    let(:path) { repository_path.delete_suffix('.git') }

    it 'redirects requests to /info/refs', type: :request do
      expect(get("#{path}/info/refs")).to redirect_to("#{path}.git/info/refs")
      expect(get("#{path}/info/refs?service=git-upload-pack")).to redirect_to("#{repository_path}/info/refs?service=git-upload-pack")
      expect(get("#{path}/info/refs?service=git-receive-pack")).to redirect_to("#{repository_path}/info/refs?service=git-receive-pack")
    end

    it 'does not redirect other requests' do
      expect(post("#{path}/git-upload-pack")).not_to be_routable
      expect(post("#{path}/info/refs/foo")).not_to be_routable
      expect(post("#{path}/info/refs?service=foo")).not_to be_routable
    end
  end

  it 'routes LFS endpoints' do
    oid = generate(:oid)

    expect(post("#{repository_path}/info/lfs/objects/batch")).to route_to('repositories/lfs_api#batch', **params)
    expect(post("#{repository_path}/info/lfs/objects")).to route_to('repositories/lfs_api#deprecated', **params)
    expect(get("#{repository_path}/info/lfs/objects/#{oid}")).to route_to('repositories/lfs_api#deprecated', oid: oid, **params)

    expect(post("#{repository_path}/info/lfs/locks/123/unlock")).to route_to('repositories/lfs_locks_api#unlock', id: '123', **params)
    expect(post("#{repository_path}/info/lfs/locks/verify")).to route_to('repositories/lfs_locks_api#verify', **params)

    expect(get("#{repository_path}/gitlab-lfs/objects/#{oid}")).to route_to('repositories/lfs_storage#download', oid: oid, **params)
    expect(put("#{repository_path}/gitlab-lfs/objects/#{oid}/456/authorize")).to route_to('repositories/lfs_storage#upload_authorize', oid: oid, size: '456', **params)
    expect(put("#{repository_path}/gitlab-lfs/objects/#{oid}/456")).to route_to('repositories/lfs_storage#upload_finalize', oid: oid, size: '456', **params)

    expect(put("#{repository_path}/gitlab-lfs/objects/foo")).not_to be_routable
    expect(put("#{repository_path}/gitlab-lfs/objects/#{oid}/foo")).not_to be_routable
    expect(put("#{repository_path}/gitlab-lfs/objects/#{oid}/foo/authorize")).not_to be_routable
  end
end

RSpec.shared_examples 'git repository routes without fallback' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).not_to be_routable
    end
  end

  it 'routes LFS endpoints for unmatched routes' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).not_to be_routable
  end
end

RSpec.shared_examples 'git repository routes with fallback' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).to route_to_route_not_found
    end
  end

  it 'routes LFS endpoints' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).to route_to_route_not_found
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).to route_to_route_not_found
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).to route_to_route_not_found
  end
end

RSpec.shared_examples 'git repository routes with fallback for git-upload-pack' do
  let(:container_path) { path.delete_suffix('.git') }

  context 'requests without .git format' do
    it 'does not redirect other requests' do
      expect(post("#{container_path}/git-upload-pack")).to route_to_route_not_found
    end
  end

  it 'routes LFS endpoints for unmatched routes' do
    oid = generate(:oid)

    expect(put("#{path}/gitlab-lfs/objects/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo")).not_to be_routable
    expect(put("#{path}/gitlab-lfs/objects/#{oid}/foo/authorize")).not_to be_routable
  end
end

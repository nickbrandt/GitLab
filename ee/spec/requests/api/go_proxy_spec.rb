# frozen_string_literal: true

require 'spec_helper'

describe API::GoProxy do
  let_it_be(:domain) do
    port = ::Gitlab.config.gitlab.port
    host = ::Gitlab.config.gitlab.host
    case port when 80, 443 then host else "#{host}:#{port}" end
  end

  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project_empty_repo, creator: user, path: 'my-go-lib' }
  let_it_be(:base) { "#{domain}/#{project.path_with_namespace}" }

  let_it_be(:oauth) { create :oauth_access_token, scopes: 'api', resource_owner: user }
  let_it_be(:job) { create :ci_build, user: user }
  let_it_be(:pa_token) { create :personal_access_token, user: user }

  # rubocop: disable Layout/IndentationConsistency
  let_it_be(:modules) do
    create_version(1, 0, 0, create_file('README.md', 'Hi', commit_message: 'Add README.md'))
    create_version(1, 0, 1, create_module)
    create_version(1, 0, 2, create_package('pkg'))
    create_version(1, 0, 3, create_module('mod'))
    sha1 =                  create_file('y.go', "package a\n")
    sha2 =                  create_module('v2')
    create_version(2, 0, 0, create_file('v2/x.go', "package a\n"))

    { sha: [sha1, sha2] }
  end

  context 'with an invalid module directive' do
    let_it_be(:project) { create :project_empty_repo, :public, creator: user }
    let_it_be(:base) { "#{domain}/#{project.path_with_namespace}" }

    # rubocop: disable Layout/IndentationWidth
    let_it_be(:modules) do
                              create_file('a.go', "package a\nfunc Hi() { println(\"Hello world!\") }\n")
      create_version(1, 0, 0, create_file('go.mod', "module not/a/real/module\n"))
                              create_file('v2/a.go', "package a\nfunc Hi() { println(\"Hello world!\") }\n")
      create_version(2, 0, 0, create_file('v2/go.mod', "module #{base}\n"))

      project.repository.head_commit
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      let(:resource) { "list" }

      context 'with a completely wrong directive for v1' do
        let(:module_name) { base }

        it 'returns nothing' do
          get_resource(user)

          expect_module_version_list
        end
      end

      context 'with a directive omitting the suffix for v2' do
        let(:module_name) { "#{base}/v2" }

        it 'returns nothing' do
          get_resource(user)

          expect_module_version_list
        end
      end
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
      context 'with a completely wrong directive for v1' do
        let(:module_name) { base }
        let(:resource) { "v1.0.0.info" }

        it 'returns not found' do
          get_resource(user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with a directive omitting the suffix for v2' do
        let(:module_name) { "#{base}/v2" }
        let(:resource) { "v2.0.0.info" }

        it 'returns not found' do
          get_resource(user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'with a case sensitive project and versions' do
    let_it_be(:project) { create :project_empty_repo, :public, creator: user, path: 'MyGoLib' }
    let_it_be(:base) { "#{domain}/#{project.path_with_namespace}" }
    let_it_be(:base_encoded) { base.gsub(/[A-Z]/) { |s| "!#{s.downcase}"} }

    let_it_be(:modules) do
                              create_file('README.md', 'Hi', commit_message: 'Add README.md')
      create_version(1, 0, 1, create_module, prerelease: 'prerelease')
      create_version(1, 0, 1, create_package('pkg'), prerelease: 'Prerelease')

      project.repository.head_commit
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
      let(:resource) { "list" }

      context 'with a case encoded path' do
        let(:module_name) { base_encoded }

        it 'returns the tags' do
          get_resource(user)

          expect_module_version_list('v1.0.1-prerelease', 'v1.0.1-Prerelease')
        end
      end

      context 'without a case encoded path' do
        let(:module_name) { base.downcase }

        it 'returns not found' do
          get_resource(user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
      context 'with a case encoded path' do
        let(:module_name) { base_encoded }
        let(:resource) { "v1.0.1-!prerelease.info" }

        it 'returns the uppercase tag' do
          get_resource(user)

          expect_module_version_info('v1.0.1-Prerelease')
        end
      end

      context 'without a case encoded path' do
        let(:module_name) { base_encoded }
        let(:resource) { "v1.0.1-prerelease.info" }

        it 'returns the lowercase tag' do
          get_resource(user)

          expect_module_version_info('v1.0.1-prerelease')
        end
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/list' do
    let(:resource) { "list" }

    # context 'with a private project', visibility: 'private' do
    #   let(:module_name) { base }

    #   it_behaves_like 'a module that requires auth'
    # end

    # context 'with a public project', visibility: 'public' do
    #   let(:module_name) { base }

    #   it_behaves_like 'a module that does not require auth'
    # end

    context 'for the root module' do
      let(:module_name) { base }

      it 'returns v1.0.1, v1.0.2, v1.0.3' do
        get_resource(user)

        expect_module_version_list('v1.0.1', 'v1.0.2', 'v1.0.3')
      end
    end

    context 'for the package' do
      let(:module_name) { "#{base}/pkg" }

      it 'returns nothing' do
        get_resource(user)

        expect_module_version_list
      end
    end

    context 'for the submodule' do
      let(:module_name) { "#{base}/mod" }

      it 'returns v1.0.3' do
        get_resource(user)

        expect_module_version_list('v1.0.3')
      end
    end

    context 'for the root module v2' do
      let(:module_name) { "#{base}/v2" }

      it 'returns v2.0.0' do
        get_resource(user)

        expect_module_version_list('v2.0.0')
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
    let(:resource) { "#{version}.info" }

    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:version) { "v1.0.1" }

      it 'returns correct information' do
        get_resource(user)

        expect_module_version_info(version)
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:version) { "v1.0.3" }

      it 'returns correct information' do
        get_resource(user)

        expect_module_version_info(version)
      end
    end

    context 'with the root module v2.0.0' do
      let(:module_name) { "#{base}/v2" }
      let(:version) { "v2.0.0" }

      it 'returns correct information' do
        get_resource(user)

        expect_module_version_info(version)
      end
    end

    context 'with an invalid path' do
      let(:module_name) { "#{base}/pkg" }
      let(:version) { "v1.0.3" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an invalid version' do
      let(:module_name) { "#{base}/mod" }
      let(:version) { "v1.0.1" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a pseudo-version for v1' do
      let(:module_name) { base }
      let(:commit) { project.repository.commit_by(oid: modules[:sha][0]) }
      let(:version) { "v1.0.4-0.#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}" }

      it 'returns the correct commit' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_kind_of(Hash)
        expect(json_response['Version']).to eq(version)
        expect(json_response['Time']).to eq(commit.committed_date.strftime '%Y-%m-%dT%H:%M:%S.%L%:z')
      end
    end

    context 'with a pseudo-version for v2' do
      let(:module_name) { "#{base}/v2" }
      let(:commit) { project.repository.commit_by(oid: modules[:sha][1]) }
      let(:version) { "v2.0.0-#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}" }

      it 'returns the correct commit' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_kind_of(Hash)
        expect(json_response['Version']).to eq(version)
        expect(json_response['Time']).to eq(commit.committed_date.strftime '%Y-%m-%dT%H:%M:%S.%L%:z')
      end
    end

    context 'with a pseudo-version with an invalid timestamp' do
      let(:module_name) { base }
      let(:commit) { project.repository.commit_by(oid: modules[:sha][0]) }
      let(:version) { "v1.0.4-0.00000000000000-#{commit.sha[0..11]}" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a pseudo-version with an invalid commit sha' do
      let(:module_name) { base }
      let(:commit) { project.repository.commit_by(oid: modules[:sha][0]) }
      let(:version) { "v1.0.4-0.#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-000000000000" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a pseudo-version with a short commit sha' do
      let(:module_name) { base }
      let(:commit) { project.repository.commit_by(oid: modules[:sha][0]) }
      let(:version) { "v1.0.4-0.#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..10]}" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.mod' do
    let(:resource) { "#{version}.mod" }

    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:version) { "v1.0.1" }

      it 'returns correct content' do
        get_resource(user)

        expect_module_version_mod(module_name)
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:version) { "v1.0.3" }

      it 'returns correct content' do
        get_resource(user)

        expect_module_version_mod(module_name)
      end
    end

    context 'with the root module v2.0.0' do
      let(:module_name) { "#{base}/v2" }
      let(:version) { "v2.0.0" }

      it 'returns correct content' do
        get_resource(user)

        expect_module_version_mod(module_name)
      end
    end

    context 'with an invalid path' do
      let(:module_name) { "#{base}/pkg" }
      let(:version) { "v1.0.3" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an invalid version' do
      let(:module_name) { "#{base}/mod" }
      let(:version) { "v1.0.1" }

      it 'returns not found' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.zip' do
    let(:resource) { "#{version}.zip" }

    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:version) { "v1.0.1" }

      it 'returns a zip of everything' do
        get_resource(user)

        expect_module_version_zip(module_name, version, ['README.md', 'go.mod', 'a.go'])
      end
    end

    context 'with the root module v1.0.2' do
      let(:module_name) { base }
      let(:version) { "v1.0.2" }

      it 'returns a zip of everything' do
        get_resource(user)

        expect_module_version_zip(module_name, version, ['README.md', 'go.mod', 'a.go', 'pkg/b.go'])
      end
    end

    context 'with the root module v1.0.3' do
      let(:module_name) { base }
      let(:version) { "v1.0.3" }

      it 'returns a zip of everything, excluding the submodule' do
        get_resource(user)

        expect_module_version_zip(module_name, version, ['README.md', 'go.mod', 'a.go', 'pkg/b.go'])
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:version) { "v1.0.3" }

      it 'returns a zip of the submodule' do
        get_resource(user)

        expect_module_version_zip(module_name, version, ['go.mod', 'a.go'])
      end
    end

    context 'with the root module v2.0.0' do
      let(:module_name) { "#{base}/v2" }
      let(:version) { "v2.0.0" }

      it 'returns a zip of v2 of the root module' do
        get_resource(user)

        expect_module_version_zip(module_name, version, ['go.mod', 'a.go', 'x.go'])
      end
    end
  end

  before do
    project.add_developer(user)
    stub_licensed_features(packages: true)

    modules
  end

  shared_context 'has a private project', visibility: 'private' do
    before do
      project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end
  end

  shared_context 'has a public project', visibility: 'public' do
    before do
      project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end
  end

  shared_examples 'a module that requires auth' do
    it 'returns ok with oauth token' do
      get_resource(access_token: oauth.token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns ok with job token' do
      get_resource(job_token: job.token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns ok with personal access token' do
      get_resource(personal_access_token: pa_token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns not found with no authentication' do
      get_resource
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'a module that does not require auth' do
    it 'returns ok with no authentication' do
      get_resource
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  def get_resource(user = nil, **params)
    get api("/projects/#{project.id}/packages/go/#{module_name}/@v/#{resource}", user), params: params
  end

  def create_file(path, content, commit_message: 'Add file')
    get_result("create file", Files::CreateService.new(
      project,
      project.owner,
      commit_message: commit_message,
      start_branch: 'master',
      branch_name: 'master',
      file_path: path,
      file_content: content
    ).execute)
  end

  def create_package(path, commit_message: 'Add package')
    get_result("create package '#{path}'", Files::MultiService.new(
      project,
      project.owner,
      commit_message: commit_message,
      start_branch: project.repository.root_ref,
      branch_name: project.repository.root_ref,
      actions: [
        { action: :create, file_path: path + '/b.go', content: "package b\nfunc Bye() { println(\"Goodbye world!\") }\n" }
      ]
    ).execute)
  end

  def create_module(path = '', commit_message: 'Add module')
    name = "#{domain}/#{project.path_with_namespace}"
    if path != ''
      name += '/' + path
      path += '/'
    end

    get_result("create module '#{name}'", Files::MultiService.new(
      project,
      project.owner,
      commit_message: commit_message,
      start_branch: project.repository.root_ref,
      branch_name: project.repository.root_ref,
      actions: [
        { action: :create, file_path: path + 'go.mod', content: "module #{name}\n" },
        { action: :create, file_path: path + 'a.go', content: "package a\nfunc Hi() { println(\"Hello world!\") }\n" }
      ]
    ).execute)
  end

  def create_version(major, minor, patch, sha, prerelease: nil, build: nil, tag_message: nil)
    name = "v#{major}.#{minor}.#{patch}"
    name += "-#{prerelease}" if prerelease
    name += "+#{build}" if build

    get_result("create version #{name[1..]}", Tags::CreateService.new(project, project.owner).execute(name, sha, tag_message))
  end

  def get_result(op, ret)
    raise "#{op} failed: #{ret}" unless ret[:status] == :success

    ret[:result]
  end

  def expect_module_version_list(*versions)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body.split("\n").to_set).to eq(versions.to_set)
  end

  def expect_module_version_info(version)
    time = project.repository.find_tag(version).dereferenced_target.committed_date

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to be_kind_of(Hash)
    expect(json_response['Version']).to eq(version)
    expect(json_response['Time']).to eq(time.strftime '%Y-%m-%dT%H:%M:%S.%L%:z')
  end

  def expect_module_version_mod(name)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body.split("\n", 2).first).to eq("module #{name}")
  end

  def expect_module_version_zip(path, version, entries)
    expect(response).to have_gitlab_http_status(:ok)

    entries = entries.map { |e| "#{path}@#{version}/#{e}" }.to_set
    actual = Set[]
    Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      while (entry = zip.get_next_entry)
        actual.add(entry.name)
      end
    end

    expect(actual).to eq(entries)
  end
end

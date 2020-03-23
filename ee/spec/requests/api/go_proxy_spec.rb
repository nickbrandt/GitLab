# frozen_string_literal: true

require 'spec_helper'

describe API::GoProxy do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project_empty_repo, creator: user, path: 'my-go-lib' }
  let_it_be(:base) { module_base project }

  let_it_be(:oauth) { create :oauth_access_token, scopes: 'api', resource_owner: user }
  let_it_be(:job) { create :ci_build, user: user }
  let_it_be(:pa_token) { create :personal_access_token, user: user }

  let_it_be(:modules) do
    create_version(1, 0, 0, create_readme)
    create_version(1, 0, 1, create_module)
    create_version(1, 0, 2, create_package('pkg'))
    create_version(1, 0, 3, create_module('mod'))

    project.repository.head_commit
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
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.info' do
    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:resource) { "v1.0.1.info" }

      it 'returns correct information' do
        get_resource(user)

        expect_module_version_info('v1.0.1')
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:resource) { "v1.0.3.info" }

      it 'returns correct information' do
        get_resource(user)

        expect_module_version_info('v1.0.3')
      end
    end

    context 'with an invalid path' do
      let(:module_name) { "#{base}/pkg" }
      let(:resource) { "v1.0.3.info" }

      it 'returns 404' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an invalid version' do
      let(:module_name) { "#{base}/mod" }
      let(:resource) { "v1.0.1.info" }

      it 'returns 404' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.mod' do
    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:resource) { "v1.0.1.mod" }

      it 'returns correct content' do
        get_resource(user)

        expect_module_version_mod(module_name)
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:resource) { "v1.0.3.mod" }

      it 'returns correct content' do
        get_resource(user)

        expect_module_version_mod(module_name)
      end
    end

    context 'with an invalid path' do
      let(:module_name) { "#{base}/pkg" }
      let(:resource) { "v1.0.3.mod" }

      it 'returns 404' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an invalid version' do
      let(:module_name) { "#{base}/mod" }
      let(:resource) { "v1.0.1.mod" }

      it 'returns 404' do
        get_resource(user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/packages/go/*module_name/@v/:module_version.zip' do
    context 'with the root module v1.0.1' do
      let(:module_name) { base }
      let(:resource) { "v1.0.1.zip" }

      it 'returns a zip of everything' do
        get_resource(user)

        expect_module_version_zip(Set['README.md', 'go.mod', 'a.go'])
      end
    end

    context 'with the root module v1.0.2' do
      let(:module_name) { base }
      let(:resource) { "v1.0.2.zip" }

      it 'returns a zip of everything' do
        get_resource(user)

        expect_module_version_zip(Set['README.md', 'go.mod', 'a.go', 'pkg/b.go'])
      end
    end

    context 'with the root module v1.0.3' do
      let(:module_name) { base }
      let(:resource) { "v1.0.3.zip" }

      it 'returns a zip of everything, excluding the submodule' do
        get_resource(user)

        expect_module_version_zip(Set['README.md', 'go.mod', 'a.go', 'pkg/b.go'])
      end
    end

    context 'with the submodule v1.0.3' do
      let(:module_name) { "#{base}/mod" }
      let(:resource) { "v1.0.3.zip" }

      it 'returns a zip of the submodule' do
        get_resource(user)

        expect_module_version_zip(Set['go.mod', 'a.go'])
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
    it 'returns 200 with oauth token' do
      get_resource(access_token: oauth.token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 200 with job token' do
      get_resource(job_token: job.token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 200 with personal access token' do
      get_resource(personal_access_token: pa_token)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 404 with no authentication' do
      get_resource
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'a module that does not require auth' do
    it 'returns 200 with no authentication' do
      get_resource
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  def get_resource(user = nil, **params)
    get api("/projects/#{project.id}/packages/go/#{module_name}/@v/#{resource}", user), params: params
  end

  def module_base(project)
    Gitlab::Routing.url_helpers.project_url(project).split('://', 2)[1]
  end

  def create_readme(commit_message: 'Add README.md')
    get_result("create readme", Files::CreateService.new(
      project,
      project.owner,
      commit_message: 'Add README.md',
      start_branch: 'master',
      branch_name: 'master',
      file_path: 'README.md',
      file_content: 'Hi'
    ).execute)
  end

  def create_module(path = '', commit_message: 'Add module')
    name = module_base(project)
    if path != ''
      name += '/' + path
      path += '/'
    end

    get_result("create module '#{name}'", ::Files::MultiService.new(
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

  def create_package(path, commit_message: 'Add package')
    get_result("create package '#{path}'", ::Files::MultiService.new(
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

  def create_version(major, minor, patch, sha, prerelease: nil, build: nil, tag_message: nil)
    name = "v#{major}.#{minor}.#{patch}"
    name += "-#{prerelease}" if prerelease
    name += "+#{build}" if build

    get_result("create version #{name[1..]}", ::Tags::CreateService.new(project, project.owner).execute(name, sha, tag_message))
  end

  def get_result(op, ret)
    raise "#{op} failed: #{ret}" unless ret[:status] == :success

    ret[:result]
  end

  def expect_module_version_list(*versions)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body.split("\n")).to eq(versions)
  end

  def expect_module_version_info(version)
    # time = project.repository.find_tag(version).dereferenced_target.committed_date

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to be_kind_of(Hash)
    expect(json_response['Version']).to eq(version)
    # expect(Date.parse json_response['Time']).to eq(time)
  end

  def expect_module_version_mod(name)
    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body.split("\n", 2).first).to eq("module #{name}")
  end

  def expect_module_version_zip(entries)
    expect(response).to have_gitlab_http_status(:ok)

    actual = Set[]
    Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      while (entry = zip.get_next_entry)
        actual.add(entry.name)
      end
    end

    expect(actual).to eq(entries)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'git_http routing', :aggregate_failures do
  let_it_be(:project) { create(:project, :public, :empty_repo) }

  describe 'code repositories' do
    it_behaves_like 'git repository routes' do
      let_it_be(:container) { project }
    end

    it_behaves_like 'git repository routes with fallback for git-upload-pack' do
      let(:path) { '/gitlab-org/gitlab-test.git' }
    end
  end

  describe 'project wiki repositories' do
    it_behaves_like 'git repository routes' do
      let_it_be(:container) { create(:project_wiki, :empty_repo, project: project) }
    end
  end

  describe 'personal snippet repositories' do
    it_behaves_like 'git repository routes' do
      let_it_be(:container) { create(:personal_snippet, :public, :empty_repo) }
    end
  end

  describe 'project snippet repositories' do
    it_behaves_like 'git repository routes' do
      let_it_be(:container) { create(:project_snippet, :public, :empty_repo, project: project) }
    end
  end
end

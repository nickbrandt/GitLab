require 'spec_helper'

describe SnippetsFinder do
  include ExternalAuthorizationServiceHelpers

  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:project_snippet, project: project) }
    let(:project_params) { { project: project } }
  end

  context 'external authorization service enabled' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let!(:snippet) { create(:project_snippet, :public, project: project) }

    before do
      project.add_maintainer(user)
    end

    it 'includes the result if the external service allows access' do
      external_service_allow_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to contain_exactly(snippet)
    end

    it 'does not include any results if the external service denies access' do
      external_service_deny_access(user, project)

      results = described_class.new(user, project: project).execute

      expect(results).to be_empty
    end
  end

  context 'filter by project' do
    set(:user) { create(:user) }
    set(:group) { create(:group, :public) }
    set(:project) { create(:project, :public, group: group) }
    set(:private_project_snippet) { create(:project_snippet, :private, project: project) }
    set(:internal_project_snippet) { create(:project_snippet, :internal, project: project) }
    set(:public_project_snippet) { create(:project_snippet, :public, project: project) }

    it 'returns all snippets for auditor users' do
      user = create(:user, :auditor)

      snippets = described_class.new(user, project: project).execute

      expect(snippets).to include(private_project_snippet, internal_project_snippet, public_project_snippet)
    end
  end
end

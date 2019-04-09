require 'spec_helper'

describe SnippetsFinder do
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

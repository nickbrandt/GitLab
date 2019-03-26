# frozen_string_literal: true

require 'spec_helper'

# Snippet visibility scenarios are included in more details in spec/support/snippet_visibility.rb
describe ProjectSnippetPolicy do
  let(:project) { create(:project, :public) }
  let(:snippet) { create(:project_snippet, snippet_visibility, project: project) }
  let(:author_permissions) do
    [
      :update_project_snippet,
      :admin_project_snippet
    ]
  end

  subject { described_class.new(current_user, snippet) }

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'private snippet' do
    let(:snippet_visibility) { :private }

    context 'auditor user' do
      let(:current_user) { create(:user, :auditor) }

      it do
        is_expected.to be_allowed(:read_project_snippet)
        is_expected.to be_disallowed(*author_permissions)
      end
    end
  end
end

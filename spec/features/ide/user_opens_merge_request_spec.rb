# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE merge request', :js do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, :with_diffs, :simple, source_project: project) }
  let_it_be(:user) { project.owner }
  let_it_be(:guest_user) { create(:user) }

  before_all do
    project.add_guest(guest_user)
  end

  shared_examples 'has disabled IDE link' do |text|
    it 'has disabled IDE link' do
      expect(page).to have_link(text, href: '#')
    end
  end

  shared_examples 'has IDE link' do |text|
    it 'has enabled IDE link' do
      click_link text

      wait_for_requests

      expect(page).to have_selector('.monaco-diff-editor')
      expect(page).to have_current_path(/ide.*merge_requests\/#{merge_request.iid}/)
    end
  end

  context 'project member visits merge request' do
    before do
      sign_in(user)

      visit(merge_request_path(merge_request))
    end

    it_behaves_like "has IDE link", "Open in Web IDE"

    context 'in diffs page' do
      before do
        click_link "Changes"
      end

      it_behaves_like "has IDE link", "Web IDE"
    end
  end

  context 'non-member visits merge request' do
    before do
      sign_in(guest_user)

      visit(merge_request_path(merge_request))
    end

    it_behaves_like "has disabled IDE link", "Open in Web IDE"

    context 'in diffs page' do
      before do
        click_link "Changes"
      end

      it_behaves_like "has disabled IDE link", "Web IDE"
    end
  end
end

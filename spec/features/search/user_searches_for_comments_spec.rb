# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for comments' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)

    visit(project_path(project))
  end

  context 'when a comment is in commits' do
    context 'when comment belongs to an invalid commit' do
      let(:comment) { create(:note_on_commit, author: user, project: project, commit_id: 12345678, note: 'Bug here') }

      it 'finds a commit' do
        submit_search(comment.note)
        select_search_scope('Comments')

        page.within('.results') do
          expect(page).to have_content('Commit deleted')
          expect(page).to have_content('12345678')
        end
      end
    end
  end

  context 'when a comment is in a snippet' do
    let(:snippet) { create(:project_snippet, :private, project: project, author: user, title: 'Some title') }
    let(:comment) { create(:note, noteable: snippet, author: user, note: 'Supercalifragilisticexpialidocious', project: project) }

    it 'finds a snippet' do
      submit_search(comment.note)
      select_search_scope('Comments')

      expect(page).to have_selector('.results', text: snippet.title)
    end
  end

  context 'when search times out' do
    before do
      allow_next_instance_of(SearchService) do |service|
        allow(service).to receive(:search_objects).and_raise(ActiveRecord::QueryCanceled)
      end

      visit(search_path(search: 'test', scope: 'notes'))
    end

    it 'renders timeout information' do
      expect(page).to have_content('Your search timed out')
    end

    it 'sets tab count to 0' do
      expect(page.find('.search-filter .active')).to have_text('0')
    end
  end
end

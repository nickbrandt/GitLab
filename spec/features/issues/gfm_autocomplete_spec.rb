# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete', :js do
  let_it_be(:user_xss_title) { 'eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;' }
  let_it_be(:user_xss) { create(:user, name: user_xss_title, username: 'xss.user') }
  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:user2) { create(:user, name: 'Marge Simpson', username: 'msimpson') }
  let_it_be(:group) { create(:group, name: 'Ancestor') }
  let_it_be(:child_group) { create(:group, parent: group, name: 'My group') }
  let_it_be(:project) { create(:project, group: child_group) }
  let_it_be(:label) { create(:label, project: project, title: 'special+') }

  let(:issue) { create(:issue, project: project) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(user_xss)
    project.add_maintainer(user2)
  end

  describe 'when tribute_autocomplete feature flag is off' do
    before do
      stub_feature_flags(tribute_autocomplete: false)

      sign_in(user)
      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'updates issue description with GFM reference' do
      click_button 'Edit title and description'

      wait_for_requests

      fill_in 'Description', with: "@#{user.name[0...3]}"

      wait_for_requests

      find_highlighted_autocomplete_item.click

      click_button 'Save changes'

      wait_for_requests

      expect(find('.description')).to have_text(user.to_reference)
    end

    it 'opens quick action autocomplete when updating description' do
      click_button 'Edit title and description'

      fill_in 'Description', with: '/'

      expect(find_autocomplete_menu).to be_visible
    end

    it 'opens autocomplete menu when field starts with text' do
      fill_in 'Comment', with: '@'

      expect(find_autocomplete_menu).to be_visible
    end

    it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
      issue_xss_title = 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;'
      create(:issue, project: project, title: issue_xss_title)

      fill_in 'Comment', with: '#'

      wait_for_requests

      expect(find_autocomplete_menu).to have_text(issue_xss_title)
    end

    it 'opens autocomplete menu for Username when field starts with text with item escaping HTML characters' do
      fill_in 'Comment', with: '@ev'

      wait_for_requests

      expect(find_highlighted_autocomplete_item).to have_text(user_xss.username)
    end

    it 'opens autocomplete menu for Milestone when field starts with text with item escaping HTML characters' do
      milestone_xss_title = 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a'
      create(:milestone, project: project, title: milestone_xss_title)

      fill_in 'Comment', with: '%'

      wait_for_requests

      expect(find_autocomplete_menu).to have_text('alert milestone')
    end

    it 'doesnt open autocomplete menu character is prefixed with text' do
      fill_in 'Comment', with: 'testing@'

      expect(page).not_to have_css('.atwho-view')
    end

    it 'doesnt select the first item for non-assignee dropdowns' do
      fill_in 'Comment', with: ':'

      wait_for_requests

      expect(find_autocomplete_menu).not_to have_css('.cur')
    end

    it 'does not open autocomplete menu when ":" is prefixed by a number and letters' do
      # Number.
      fill_in 'Comment', with: '7:'
      expect(page).not_to have_css('.atwho-view')

      # ASCII letter.
      fill_in 'Comment', with: 'w:'
      expect(page).not_to have_css('.atwho-view')

      # Non-ASCII letter.
      fill_in 'Comment', with: 'Ё:'
      expect(page).not_to have_css('.atwho-view')
    end

    it 'selects the first item for assignee dropdowns' do
      fill_in 'Comment', with: '@'

      wait_for_requests

      expect(find_autocomplete_menu).to have_css('.cur:first-of-type')
    end

    it 'includes items for assignee dropdowns with non-ASCII characters in name' do
      fill_in 'Comment', with: "@#{user.name[0...8]}"

      wait_for_requests

      expect(find_autocomplete_menu).to have_text(user.name)
    end

    it 'searches across full name for assignees' do
      fill_in 'Comment', with: '@speciąlsome'

      wait_for_requests

      expect(find_highlighted_autocomplete_item).to have_text(user.name)
    end

    it 'shows names that start with the query as the top result' do
      fill_in 'Comment', with: '@mar'

      wait_for_requests

      expect(find_highlighted_autocomplete_item).to have_text(user2.name)
    end

    it 'shows usernames that start with the query as the top result' do
      fill_in 'Comment', with: '@msi'

      wait_for_requests

      expect(find_highlighted_autocomplete_item).to have_text(user2.name)
    end

    # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/321925
    it 'shows username when pasting then pressing Enter' do
      fill_in 'Comment', with: "@#{user.username}\n"

      expect(find_field('Comment').value).to have_text "@#{user.username}"
    end

    it 'does not show `@undefined` when pressing `@` then Enter' do
      fill_in 'Comment', with: "@\n"

      expect(find_field('Comment').value).to have_text '@'
      expect(find_field('Comment').value).not_to have_text '@undefined'
    end

    it 'selects the first item for non-assignee dropdowns if a query is entered' do
      fill_in 'Comment', with: ':1'

      wait_for_requests

      expect(find_autocomplete_menu).to have_css('.cur:first-of-type')
    end

    context 'if a selected value has special characters' do
      it 'wraps the result in double quotes' do
        fill_in 'Comment', with: "~#{label.title[0]}"

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text("~\"#{label.title}\"")
      end

      it "shows dropdown after a new line" do
        fill_in 'Comment', with: "test\n\n@"

        expect(find_autocomplete_menu).to be_visible
      end

      it "does not show dropdown when preceded with a special character" do
        fill_in 'Comment', with: '@@'

        expect(page).not_to have_css('.atwho-view')
      end

      it 'doesn\'t wrap for assignee values' do
        fill_in 'Comment', with: "@#{user.username[0]}"

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text("@#{user.username}")
      end

      it 'doesn\'t wrap for emoji values' do
        fill_in 'Comment', with: ':cartwheel_'

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text('cartwheel_tone1')
      end

      it 'doesn\'t open autocomplete after non-word character' do
        fill_in 'Comment', with: "@#{user.username[0..2]}!"

        expect(page).not_to have_css('.atwho-view')
      end

      it 'doesn\'t open autocomplete if there is no space before' do
        fill_in 'Comment', with: "hello:#{user.username[0..2]}"

        expect(page).not_to have_css('.atwho-view')
      end

      it 'triggers autocomplete after selecting a quick action' do
        fill_in 'Comment', with: '/as'

        find_highlighted_autocomplete_item.click

        expect(find_autocomplete_menu).to have_text(user.username)
      end

      it 'does not limit quick actions autocomplete list to 5' do
        fill_in 'Comment', with: '/'

        expect(find_autocomplete_menu).to have_css('li', minimum: 6)
      end
    end

    context 'assignees' do
      let(:issue_assignee) { create(:issue, project: project) }
      let(:unassigned_user) { create(:user) }

      before do
        issue_assignee.update(assignees: [user])

        project.add_maintainer(unassigned_user)
      end

      it 'lists users who are currently not assigned to the issue when using /assign' do
        visit project_issue_path(project, issue_assignee)

        fill_in 'Comment', with: '/as'

        find_highlighted_autocomplete_item.click

        expect(find_autocomplete_menu).not_to have_text(user.username)
        expect(find_autocomplete_menu).to have_text(unassigned_user.username)
      end

      it 'shows dropdown on new issue form' do
        visit new_project_issue_path(project)

        fill_in 'Description', with: '/ass'

        find_highlighted_autocomplete_item.click

        expect(find_autocomplete_menu).to have_text(unassigned_user.username)
        expect(find_autocomplete_menu).to have_text(user.username)
      end
    end

    context 'labels' do
      it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
        label_xss_title = 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a'
        create(:label, project: project, title: label_xss_title)

        fill_in 'Comment', with: '~'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('alert label')
      end

      it 'allows colons when autocompleting scoped labels' do
        create(:label, project: project, title: 'scoped:label')

        fill_in 'Comment', with: '~scoped:'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('scoped:label')
      end

      it 'allows colons when autocompleting scoped labels with double colons' do
        create(:label, project: project, title: 'scoped::label')

        fill_in 'Comment', with: '~scoped::'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('scoped::label')
      end

      it 'allows spaces when autocompleting multi-word labels' do
        create(:label, project: project, title: 'Accepting merge requests')

        fill_in 'Comment', with: '~Accepting merge'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('Accepting merge requests')
      end

      it 'only autocompletes the latest label' do
        create(:label, project: project, title: 'Accepting merge requests')
        create(:label, project: project, title: 'Accepting job applicants')

        fill_in 'Comment', with: '~Accepting merge requests foo bar ~Accepting job'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('Accepting job applicants')
      end

      it 'does not autocomplete labels if no tilde is typed' do
        create(:label, project: project, title: 'Accepting merge requests')

        fill_in 'Comment', with: 'Accepting merge'

        wait_for_requests

        expect(page).not_to have_css('.atwho-view')
      end
    end

    context 'when other notes are destroyed' do
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

      # This is meant to protect against this issue https://gitlab.com/gitlab-org/gitlab/-/issues/228729
      it 'keeps autocomplete key listeners' do
        visit project_issue_path(project, issue)
        note = find_field('Comment')

        start_comment_with_emoji(note, '.atwho-view li')

        start_and_cancel_discussion

        note.fill_in(with: '')
        start_comment_with_emoji(note, '.atwho-view li')
        note.native.send_keys(:enter)

        expect(note.value).to eql('Hello :100: ')
      end
    end

    shared_examples 'autocomplete suggestions' do
      it 'suggests objects correctly' do
        fill_in 'Comment', with: object.class.reference_prefix

        find_autocomplete_menu.find('li').click

        expect(find_field('Comment').value).to have_text(expected_body)
      end
    end

    context 'issues' do
      let(:object) { issue }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'merge requests' do
      let(:object) { create(:merge_request, source_project: project) }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'project snippets' do
      let!(:object) { create(:project_snippet, project: project, title: 'code snippet') }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'label' do
      let!(:object) { label }
      let(:expected_body) { object.title }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'milestone' do
      let!(:object) { create(:milestone, project: project) }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end
  end

  describe 'when tribute_autocomplete feature flag is on' do
    before do
      stub_feature_flags(tribute_autocomplete: true)

      sign_in(user)
      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'updates issue description with GFM reference' do
      click_button 'Edit title and description'

      wait_for_requests

      fill_in 'Description', with: "@#{user.name[0...3]}"

      wait_for_requests

      find_highlighted_tribute_autocomplete_menu.click

      click_button 'Save changes'

      wait_for_requests

      expect(find('.description')).to have_text(user.to_reference)
    end

    it 'opens autocomplete menu when field starts with text' do
      fill_in 'Comment', with: '@'

      expect(find_tribute_autocomplete_menu).to be_visible
    end

    it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
      issue_xss_title = 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;'
      create(:issue, project: project, title: issue_xss_title)

      fill_in 'Comment', with: '#'

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_text(issue_xss_title)
    end

    it 'opens autocomplete menu for Username when field starts with text with item escaping HTML characters' do
      fill_in 'Comment', with: '@ev'

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_text(user_xss.username)
    end

    it 'opens autocomplete menu for Milestone when field starts with text with item escaping HTML characters' do
      milestone_xss_title = 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a'
      create(:milestone, project: project, title: milestone_xss_title)

      fill_in 'Comment', with: '%'

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_text('alert milestone')
    end

    it 'does not open autocomplete menu when trigger character is prefixed with text' do
      fill_in 'Comment', with: 'testing@'

      expect(page).not_to have_css('.tribute-container')
    end

    it 'does not open autocomplete menu when ":" is prefixed by a number and letters' do
      # Number.
      fill_in 'Comment', with: '7:'
      expect(page).not_to have_css('.tribute-container')

      # ASCII letter.
      fill_in 'Comment', with: 'w:'
      expect(page).not_to have_css('.tribute-container')

      # Non-ASCII letter.
      fill_in 'Comment', with: 'Ё:'
      expect(page).not_to have_css('.tribute-container')
    end

    it 'selects the first item for assignee dropdowns' do
      fill_in 'Comment', with: '@'

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_css('.highlight:first-of-type')
    end

    it 'includes items for assignee dropdowns with non-ASCII characters in name' do
      fill_in 'Comment', with: "@#{user.name[0...8]}"

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_text(user.name)
    end

    it 'selects the first item for non-assignee dropdowns if a query is entered' do
      fill_in 'Comment', with: ':1'

      wait_for_requests

      expect(find_tribute_autocomplete_menu).to have_css('.highlight:first-of-type')
    end

    context 'when autocompleting for groups' do
      it 'shows the group when searching for the name of the group' do
        fill_in 'Comment', with: '@mygroup'

        expect(find_tribute_autocomplete_menu).to have_text('My group')
      end

      it 'does not show the group when searching for the name of the parent of the group' do
        fill_in 'Comment', with: '@ancestor'

        expect(find_tribute_autocomplete_menu).not_to have_text('My group')
      end
    end

    context 'if a selected value has special characters' do
      it 'wraps the result in double quotes' do
        fill_in 'Comment', with: "~#{label.title[0]}"

        find_highlighted_tribute_autocomplete_menu.click

        expect(find_field('Comment').value).to have_text("~\"#{label.title}\"")
      end

      it "shows dropdown after a new line" do
        fill_in 'Comment', with: "test\n\n@"

        expect(find_tribute_autocomplete_menu).to be_visible
      end

      it 'doesn\'t wrap for assignee values' do
        fill_in 'Comment', with: "@#{user.username[0..2]}"

        find_highlighted_tribute_autocomplete_menu.click

        expect(find_field('Comment').value).to have_text("@#{user.username}")
      end

      it 'does not wrap for emoji values' do
        fill_in 'Comment', with: ':cartwheel_'

        find_highlighted_tribute_autocomplete_menu.click

        expect(find_field('Comment').value).to have_text('cartwheel_tone1')
      end

      it 'does not open autocomplete if there is no space before' do
        fill_in 'Comment', with: "hello:#{user.username[0..2]}"

        expect(page).not_to have_css('.tribute-container')
      end

      it 'autocompletes for quick actions' do
        fill_in 'Comment', with: '/as'

        find_highlighted_tribute_autocomplete_menu.click

        expect(find_field('Comment').value).to have_text('/assign')
      end
    end

    context 'assignees' do
      let(:issue_assignee) { create(:issue, project: project) }
      let(:unassigned_user) { create(:user) }

      before do
        issue_assignee.update(assignees: [user])

        project.add_maintainer(unassigned_user)
      end

      it 'lists users who are currently not assigned to the issue when using /assign' do
        visit project_issue_path(project, issue_assignee)

        note = find_field('Comment')
        note.native.send_keys('/assign ')
        # The `/assign` ajax response might replace the one by `@` below causing a failed test
        # so we need to wait for the `/assign` ajax request to finish first
        wait_for_requests
        note.native.send_keys('@')
        wait_for_requests

        expect(find_tribute_autocomplete_menu).not_to have_text(user.username)
        expect(find_tribute_autocomplete_menu).to have_text(unassigned_user.username)
      end

      it 'lists users who are currently not assigned to the issue when using /assign on the second line' do
        visit project_issue_path(project, issue_assignee)

        note = find_field('Comment')
        note.native.send_keys('/assign @user2')
        note.native.send_keys(:enter)
        note.native.send_keys('/assign ')
        # The `/assign` ajax response might replace the one by `@` below causing a failed test
        # so we need to wait for the `/assign` ajax request to finish first
        wait_for_requests
        note.native.send_keys('@')
        wait_for_requests

        expect(find_tribute_autocomplete_menu).not_to have_text(user.username)
        expect(find_tribute_autocomplete_menu).to have_text(unassigned_user.username)
      end
    end

    context 'labels' do
      it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
        label_xss_title = 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a'
        create(:label, project: project, title: label_xss_title)

        fill_in 'Comment', with: '~'

        wait_for_requests

        expect(find_tribute_autocomplete_menu).to have_text('alert label')
      end

      it 'allows colons when autocompleting scoped labels' do
        create(:label, project: project, title: 'scoped:label')

        fill_in 'Comment', with: '~scoped:'

        wait_for_requests

        expect(find_tribute_autocomplete_menu).to have_text('scoped:label')
      end

      it 'allows colons when autocompleting scoped labels with double colons' do
        create(:label, project: project, title: 'scoped::label')

        fill_in 'Comment', with: '~scoped::'

        wait_for_requests

        expect(find_tribute_autocomplete_menu).to have_text('scoped::label')
      end

      it 'autocompletes multi-word labels' do
        create(:label, project: project, title: 'Accepting merge requests')

        fill_in 'Comment', with: '~Acceptingmerge'

        wait_for_requests

        expect(find_tribute_autocomplete_menu).to have_text('Accepting merge requests')
      end

      it 'only autocompletes the latest label' do
        create(:label, project: project, title: 'documentation')
        create(:label, project: project, title: 'feature')

        fill_in 'Comment', with: '~documentation foo bar ~feat'
        # Invoke autocompletion
        find_field('Comment').native.send_keys(:right)

        wait_for_requests

        expect(find_tribute_autocomplete_menu).to have_text('feature')
        expect(find_tribute_autocomplete_menu).not_to have_text('documentation')
      end

      it 'does not autocomplete labels if no tilde is typed' do
        create(:label, project: project, title: 'documentation')

        fill_in 'Comment', with: 'document'

        wait_for_requests

        expect(page).not_to have_css('.tribute-container')
      end
    end

    context 'when other notes are destroyed' do
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

      # This is meant to protect against this issue https://gitlab.com/gitlab-org/gitlab/-/issues/228729
      it 'keeps autocomplete key listeners' do
        visit project_issue_path(project, issue)
        note = find_field('Comment')

        start_comment_with_emoji(note, '.tribute-container li')

        start_and_cancel_discussion

        note.fill_in(with: '')
        start_comment_with_emoji(note, '.tribute-container li')
        note.native.send_keys(:enter)

        expect(note.value).to eql('Hello :100: ')
      end
    end

    shared_examples 'autocomplete suggestions' do
      it 'suggests objects correctly' do
        fill_in 'Comment', with: object.class.reference_prefix

        find_tribute_autocomplete_menu.find('li').click

        expect(find_field('Comment').value).to have_text(expected_body)
      end
    end

    context 'issues' do
      let(:object) { issue }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'merge requests' do
      let(:object) { create(:merge_request, source_project: project) }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'project snippets' do
      let!(:object) { create(:project_snippet, project: project, title: 'code snippet') }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'label' do
      let!(:object) { label }
      let(:expected_body) { object.title }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'milestone' do
      let!(:object) { create(:milestone, project: project) }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end
  end

  private

  def start_comment_with_emoji(note, selector)
    note.native.send_keys('Hello :10')

    wait_for_requests

    find(selector, text: '100')
  end

  def start_and_cancel_discussion
    fill_in('Reply to comment', with: 'Whoops!')

    page.accept_alert 'Are you sure you want to cancel creating this comment?' do
      click_button('Cancel')
    end

    wait_for_requests
  end

  def find_autocomplete_menu
    find('.atwho-view ul', visible: true)
  end

  def find_highlighted_autocomplete_item
    find('.atwho-view li.cur', visible: true)
  end

  def find_tribute_autocomplete_menu
    find('.tribute-container ul', visible: true)
  end

  def find_highlighted_tribute_autocomplete_menu
    find('.tribute-container li.highlight', visible: true)
  end
end

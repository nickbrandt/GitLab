# frozen_string_literal: true

require 'spec_helper'

describe 'Requirements list', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:requirement1) { create(:requirement, project: project, title: 'Some requirement-1', author: user, created_at: 5.days.ago, updated_at: 2.days.ago) }
  let_it_be(:requirement2) { create(:requirement, project: project, title: 'Some requirement-2', author: user, created_at: 6.days.ago, updated_at: 2.days.ago) }
  let_it_be(:requirement3) { create(:requirement, project: project, title: 'Some requirement-3', author: user, created_at: 7.days.ago, updated_at: 2.days.ago) }
  let_it_be(:requirement_archived) { create(:requirement, project: project, title: 'Some requirement-3', state: :archived, author: user, created_at: 8.days.ago, updated_at: 2.days.ago) }

  before do
    stub_licensed_features(requirements: true)
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when requirements exist for the project' do
    before do
      visit project_requirements_path(project)

      wait_for_requests
    end

    it 'shows the requirements in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Requirements')
      expect(first('.nav-sidebar .active a .count')).to have_content('4')
    end

    it 'shows requirements tabs for each status type' do
      page.within('.requirements-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(find('li > a#state-opened')[:title]).to eq('Filter by requirements that are currently opened.')
        expect(find('li > a#state-opened .badge')).to have_content('3')

        expect(page).to have_selector('li > a#state-archived')
        expect(find('li > a#state-archived')[:title]).to eq('Filter by requirements that are currently archived.')
        expect(find('li > a#state-archived .badge')).to have_content('1')

        expect(page).to have_selector('li > a#state-all')
        expect(find('li > a#state-all')[:title]).to eq('Show all requirements.')
        expect(find('li > a#state-all .badge')).to have_content('4')
      end
    end

    it 'shows button "New requirement"' do
      page.within('.nav-controls') do
        expect(page).to have_selector('button.js-new-requirement')
        expect(find('button.js-new-requirement')).to have_content('New requirement')
      end
    end

    context 'open tab' do
      it 'shows list of all open requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 3)
        end
      end

      it 'shows title, metadata and actions within each requirement item' do
        page.within('.requirements-list li.requirement', match: :first) do
          expect(page.find('.issuable-reference')).to have_content("REQ-#{requirement1.iid}")
          expect(page.find('.issue-title-text')).to have_content(requirement1.title)
          expect(page.find('.issuable-authored')).to have_content('created 5 days ago by')
          expect(page.find('.author')).to have_content(user.name)
          expect(page.find('.controls')).to have_selector('li.requirement-edit button[title="Edit"]')
          expect(page.find('.controls')).to have_selector('li.requirement-archive button[title="Archive"]')
          expect(page.find('.issuable-updated-at')).to have_content('updated 2 days ago')
        end
      end
    end

    context 'archived tab' do
      before do
        find('li > a#state-archived').click

        wait_for_requests
      end

      it 'shows list of all archived requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 1)
        end
      end

      it 'shows title, metadata and actions within each requirement item' do
        page.within('.requirements-list li.requirement', match: :first) do
          expect(page.find('.issuable-reference')).to have_content("REQ-#{requirement_archived.iid}")
          expect(page.find('.issue-title-text')).to have_content(requirement_archived.title)
          expect(page.find('.issuable-authored')).to have_content('created 1 week ago by')
          expect(page.find('.author')).to have_content(user.name)
          expect(page.find('.issuable-updated-at')).to have_content('updated 2 days ago')
        end
      end
    end

    context 'archived tab' do
      before do
        find('li > a#state-all').click

        wait_for_requests
      end

      it 'shows list of all requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 4)
        end
      end
    end
  end
end

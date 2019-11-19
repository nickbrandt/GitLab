# frozen_string_literal: true

require 'spec_helper'

describe 'Snippet elastic search', :js, :elastic, :aggregate_failures, :sidekiq_might_not_need_inline do
  let(:public_project) { create(:project, :public) }
  let(:authorized_user) { create(:user) }
  let(:authorized_project) { create(:project, namespace: authorized_user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    authorized_project.add_maintainer(authorized_user)

    create(:personal_snippet, :public, content: 'public personal snippet')
    create(:project_snippet, :public, content: 'public project snippet', project: public_project)

    create(:personal_snippet, :internal, content: 'internal personal snippet')
    create(:project_snippet, :internal, content: 'internal project snippet', project: public_project)

    create(:personal_snippet, :private, content: 'private personal snippet')
    create(:project_snippet, :private, content: 'private project snippet', project: public_project)

    create(:personal_snippet, :private, content: 'authorized personal snippet', author: authorized_user)
    create(:project_snippet, :private, content: 'authorized project snippet', project: authorized_project)

    Gitlab::Elastic::Helper.refresh_index

    sign_in(current_user) if current_user
    visit explore_snippets_path
    submit_search('snippet')
  end

  # TODO: Reenable support for public/internal project snippets
  # https://gitlab.com/gitlab-org/gitlab/issues/35760

  context 'as anonymous user' do
    let(:current_user) { nil }

    it 'finds only public snippets' do
      within('.results') do
        expect(page).to have_content('public personal snippet')
        expect(page).not_to have_content('public project snippet')

        expect(page).not_to have_content('internal personal snippet')
        expect(page).not_to have_content('internal project snippet')

        expect(page).not_to have_content('authorized personal snippet')
        expect(page).not_to have_content('authorized project snippet')

        expect(page).not_to have_content('private personal snippet')
        expect(page).not_to have_content('private project snippet')
      end
    end
  end

  context 'as logged in user' do
    let(:current_user) { create(:user) }

    it 'finds only public and internal snippets' do
      within('.results') do
        expect(page).to have_content('public personal snippet')
        expect(page).not_to have_content('public project snippet')

        expect(page).to have_content('internal personal snippet')
        expect(page).not_to have_content('internal project snippet')

        expect(page).not_to have_content('private personal snippet')
        expect(page).not_to have_content('private project snippet')

        expect(page).not_to have_content('authorized personal snippet')
        expect(page).not_to have_content('authorized project snippet')
      end
    end
  end

  context 'as authorized user' do
    let(:current_user) { authorized_user }

    it 'finds only public, internal, and authorized private snippets' do
      within('.results') do
        expect(page).to have_content('public personal snippet')
        expect(page).not_to have_content('public project snippet')

        expect(page).to have_content('internal personal snippet')
        expect(page).not_to have_content('internal project snippet')

        expect(page).not_to have_content('private personal snippet')
        expect(page).not_to have_content('private project snippet')

        expect(page).to have_content('authorized personal snippet')
        expect(page).to have_content('authorized project snippet')
      end
    end
  end

  context 'as administrator' do
    let(:current_user) { create(:admin) }

    it 'finds all snippets' do
      within('.results') do
        expect(page).to have_content('public personal snippet')
        expect(page).to have_content('public project snippet')

        expect(page).to have_content('internal personal snippet')
        expect(page).to have_content('internal project snippet')

        expect(page).to have_content('private personal snippet')
        expect(page).to have_content('private project snippet')

        expect(page).to have_content('authorized personal snippet')
        expect(page).to have_content('authorized project snippet')
      end
    end
  end
end

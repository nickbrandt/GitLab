# frozen_string_literal: true

require 'spec_helper'

describe 'Geo clone instructions', :geo, :js do
  include Devise::Test::IntegrationHelpers
  include ::EE::GeoHelpers

  let(:project) { create(:project, :empty_repo) }
  let(:developer) { create(:user) }

  before do
    primary = create(:geo_node, :primary, url: 'https://primary.domain.com')
    primary.update_columns(clone_url_prefix: 'git@primary.domain.com:')
    secondary = create(:geo_node)

    stub_current_geo_node(secondary)

    project.add_developer(developer)
    sign_in(developer)
  end

  context 'with an SSH key' do
    before do
      create(:personal_key, user: developer)
    end

    it 'displays clone instructions' do
      visit_project

      show_geo_clone_instructions

      expect_instructions_for('ssh')
      expect_instructions_for('http')
    end
  end

  def visit_project
    visit project_path(project)
  end

  def show_geo_clone_instructions
    find('.qa-clone-dropdown').click
    find('.btn-geo', match: :first).click
  end

  def expect_instructions_for(protocol)
    primary_remote = primary_url(protocol)
    secondary_remote = secondary_url(protocol)

    expect(page).to have_content('How to work faster with Geo')
    expect(page.find("#geo-info-1-#{protocol}").value).to eq "git clone #{secondary_remote}"
    # the primary_url does not return the full url, but just the part up to the host:
    expect(page.find("#geo-info-2-#{protocol}").value).to start_with("git remote set-url --push origin #{primary_remote}")
  end

  def primary_url(protocol)
    case protocol
    when 'ssh'
      'git@primary.domain.com:'
    when 'http'
      'https://primary.domain.com'
    end
  end

  def secondary_url(protocol)
    case protocol
    when 'ssh'
      project.ssh_url_to_repo
    when 'http'
      project.http_url_to_repo
    end
  end
end

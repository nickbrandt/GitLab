# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Licenses app", :js do
  let(:admin) { create(:admin) }
  let!(:licenses) do
    [
      create(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export),
      create(:license, data: build(:gitlab_license, expires_at: Date.today - 10, restrictions: { active_user_count: 2000, plan: 'ultimate' }).export)
    ]
  end

  def visit_page
    visit(admin_license_path)

    find('.js-license-table', match: :first)
  end

  def assert_usage_row(row, license)
    header, seats_in_license, seats_in_use, historical_max, overage = row.find_all('.license-cell').to_a

    expect(header).to have_content 'Usage'
    expect(seats_in_license).to have_content 'Seats in license'
    expect(seats_in_license).to have_content license.restrictions[:active_user_count]
    expect(seats_in_use).to have_content 'Seats currently in use'

    if license.exclude_guests_from_active_count?
      expect(seats_in_use).to have_content User.active.excluding_guests.count
    else
      expect(seats_in_use).to have_content User.active.count
    end

    expect(historical_max).to have_content 'Max seats used'
    expect(historical_max).to have_content license.historical_max
    expect(overage).to have_content 'Users outside of license'
    expect(overage).to have_content license.overage
  end

  def assert_validity_row(row, license)
    header, starts_at, expires_at, created_at = row.find_all('.license-cell').to_a

    expect(header).to have_content 'Validity'
    expect(starts_at).to have_content 'Start date'
    expect(starts_at).to have_content license.starts_at.strftime('%B %-d, %Y')
    expect(expires_at).to have_content 'End date'
    expect(expires_at).to have_content license.expires_at.strftime('%B %-d, %Y')

    if license.expired?
      expect(expires_at).to have_content 'Expired'
    else
      expect(expires_at).not_to have_content 'Expired'
    end

    expect(created_at).to have_content 'Uploaded on'
    expect(created_at).to have_content license.created_at.strftime('%B %-d, %Y')
  end

  def assert_registration_row(row, license)
    header, name, email, company = row.find_all('.license-cell').to_a

    expect(header).to have_content 'Registration'
    expect(name).to have_content 'Licensed to'
    expect(name).to have_content license.licensee['Name'] || 'Unknown'
    expect(email).to have_content 'Email address'
    expect(email).to have_content license.licensee['Email'] || 'Unknown'
    expect(company).to have_content 'Company'
    expect(company).to have_content license.licensee['Company'] || 'Unknown'
  end

  def assert_license_card(card, license)
    top_row, middle_row, bottom_row = card.find_all('.license-row').to_a

    assert_usage_row(top_row, license)
    assert_validity_row(middle_row, license)
    assert_registration_row(bottom_row, license)
  end

  before do
    stub_feature_flags(licenses_app: true)
    sign_in(admin)
  end

  it 'renders a list of licenses' do
    visit_page

    licenses.each_with_index do |license, index|
      assert_license_card(find_all('.license-table')[index], licenses.reverse[index])
    end
  end

  it 'deletes a license' do
    visit_page

    license_card = find('.license-card', match: :first)
    current_id = License.current.id

    license_card.find('.js-manage-license').click

    page.accept_alert 'Are you sure you want to permanently delete this license?' do
      license_card.find('.js-delete-license').click
    end

    expect(license_card).not_to have_selector('.license-card-loading')
    expect(License.find_by(id: current_id)).to be_nil
  end
end

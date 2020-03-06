# frozen_string_literal: true

require 'spec_helper'

describe 'admin Geo Uploads', :js, :geo do
  let!(:geo_node) { create(:geo_node) }
  let!(:synced_registry) { create(:geo_upload_registry, :with_file, :attachment, success: true) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    sign_in(create(:admin))
  end

  describe 'remove an orphaned Tracking Entry' do
    before do
      synced_registry.upload.destroy!
      visit(admin_geo_uploads_path)
      wait_for_requests
    end

    it 'removes an existing Geo Upload' do
      card_count = page.all(:css, '.upload-card').length

      page.within(find('.upload-card', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove entry')
      end
      # Wait for remove confirmation
      expect(page.find('.gl-toast')).to have_text('removed')

      expect(page.all(:css, '.upload-card').length).to be(card_count - 1)
    end
  end
end

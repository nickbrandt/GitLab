# frozen_string_literal: true

RSpec.shared_context 'rake task object storage shared context' do
  before do
    allow(Settings.uploads.object_store).to receive(:[]=).and_call_original
  end

  around do |example|
    old_direct_upload_setting     = Settings.uploads.object_store['direct_upload']
    old_background_upload_setting = Settings.uploads.object_store['background_upload']

    Settings.uploads.object_store['direct_upload']     = true
    Settings.uploads.object_store['background_upload'] = true

    example.run

    Settings.uploads.object_store['direct_upload']     = old_direct_upload_setting
    Settings.uploads.object_store['background_upload'] = old_background_upload_setting
  end
end

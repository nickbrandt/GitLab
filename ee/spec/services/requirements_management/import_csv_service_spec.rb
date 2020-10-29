# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ImportCsvService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader).execute
  end

  context 'when user can create requirements' do
    before do
      project.add_reporter(user)
      stub_licensed_features(requirements: true)
    end

    include_examples 'issuable import csv service', 'requirement' do
      let(:issuables) { project.requirements }
      let(:email_method) { :import_requirements_csv_email }
    end
  end

  context 'when user cannot create requirements' do
    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

    it 'raises an exception' do
      expect { service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end

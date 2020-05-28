# frozen_string_literal: true

require 'spec_helper'

describe 'projects/issues/import_csv/_button' do
  include Devise::Test::ControllerHelpers

  context 'when the user is not an admin' do
    before do
      render
    end

    it 'shows a dropdown button to import CSV' do
      expect(rendered).to have_text('Import CSV')
    end

    it 'does not show a button to import from Jira' do
      expect(rendered).not_to have_text('Import from Jira')
    end
  end

  context 'when the user is an admin' do
    before do
      allow(view).to receive(:can?).and_return(true)
      allow(view).to receive(:project_import_jira_path).and_return('import/jira')

      render
    end

    it 'shows a dropdown button to import CSV' do
      expect(rendered).to have_text('Import CSV')
    end

    it 'shows a button to import from Jira' do
      expect(rendered).to have_text('Import from Jira')
    end
  end
end

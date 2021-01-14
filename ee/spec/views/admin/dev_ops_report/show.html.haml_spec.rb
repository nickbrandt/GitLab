# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dev_ops_report/show.html.haml' do
  include Devise::Test::ControllerHelpers

  before do
    stub_licensed_features(devops_adoption: true)
  end

  context 'when no segment record is present' do
    it 'disables the feature' do
      expect(Feature).to receive(:enabled?).with(:devops_adoption_feature, default_enabled: false).and_return(false)

      render

      expect(rendered).not_to have_selector('#devops-adoption')
    end
  end

  context 'when at least one segment record is present' do
    before do
      create(:devops_adoption_segment)
    end

    it 'enables the feature' do
      expect(Feature).to receive(:enabled?).with(:devops_adoption_feature, default_enabled: true).and_return(true)

      render

      expect(rendered).to have_selector('#devops-adoption')
    end
  end
end

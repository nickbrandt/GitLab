# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishedIncident do
  describe 'associations' do
    it { is_expected.to belong_to(:issue).inverse_of(:status_page_published_incident) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:issue) }
  end
end

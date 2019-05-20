# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gitlab::Favicon, :request_store do
  describe '.main' do
    it 'has green favicon for development' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      expect(described_class.main).to match_asset_path 'favicon-green.png'
    end
  end
end

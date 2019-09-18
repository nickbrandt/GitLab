# frozen_string_literal: true

require 'spec_helper'

describe DashboardEnvironmentEntity do
  describe '.as_json' do
    it 'includes environment attributes' do
      environment = create(:environment)

      result = described_class.new(environment).as_json

      expect(result.keys.sort).to eq([:environment_path, :external_url, :id, :name])
    end
  end
end

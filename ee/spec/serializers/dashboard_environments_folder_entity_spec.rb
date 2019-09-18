# frozen_string_literal: true

require 'spec_helper'

describe DashboardEnvironmentsFolderEntity do
  describe '.as_json' do
    it 'includes folder and environment attributes' do
      environment = create(:environment)
      size = 1
      environment_folder = EnvironmentFolder.new(environment, size)

      result = described_class.new(environment_folder).as_json

      expect(result.keys.sort).to eq([:environment_path, :external_url, :id, :name, :size, :within_folder])
    end
  end
end

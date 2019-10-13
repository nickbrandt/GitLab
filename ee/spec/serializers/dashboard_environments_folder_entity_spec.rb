# frozen_string_literal: true

require 'spec_helper'

describe DashboardEnvironmentsFolderEntity do
  describe '.as_json' do
    it 'includes folder and environment attributes' do
      user = create(:user)
      environment = create(:environment)
      create(:deployment, project: environment.project, environment: environment, status: :success)
      size = 1
      environment_folder = EnvironmentFolder.new(environment, size)
      request = EntityRequest.new(current_user: user)

      result = described_class.new(environment_folder, request: request).as_json

      expect(result.keys.sort).to eq([:environment_path, :external_url, :id, :last_deployment, :name, :size, :within_folder])
    end
  end
end

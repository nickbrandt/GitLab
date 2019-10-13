# frozen_string_literal: true

require 'spec_helper'

describe DashboardEnvironmentsSerializer do
  describe '.represent' do
    it 'returns an empty array when there are no projects' do
      current_user = create(:user)
      projects_with_folders = {}

      result = described_class.new(current_user: current_user).represent(projects_with_folders)

      expect(result).to eq([])
    end

    it 'includes project attributes' do
      current_user = create(:user)
      project = create(:project)
      environment = create(:environment)
      size = 1
      environment_folder = EnvironmentFolder.new(environment, size)
      projects_with_folders = { project => [environment_folder] }

      result = described_class.new(current_user: current_user).represent(projects_with_folders)

      expect(result.first.keys.sort).to eq([:avatar_url, :environments, :id, :name, :namespace, :remove_path, :web_url])
    end
  end
end

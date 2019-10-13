# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::Environments::ListService do
  describe '#execute' do
    before do
      stub_licensed_features(operations_dashboard: true)
    end

    it 'returns a list of projects' do
      user = create(:user)
      project = create(:project)
      project.add_developer(user)
      user.update!(ops_dashboard_projects: [project])

      projects_with_folders = described_class.new(user).execute

      expect(projects_with_folders).to eq({ project => [] })
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(operations_dashboard: false)
      end

      it 'returns an empty hash' do
        user = create(:user)
        project = create(:project)
        project.add_developer(user)
        user.update!(ops_dashboard_projects: [project])

        projects_with_folders = described_class.new(user).execute

        expect(projects_with_folders).to eq({})
      end
    end
  end
end

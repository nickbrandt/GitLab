# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RepoPath do
  describe '.find_project' do
    let(:project) { create(:project) }

    context 'project_path matches a project alias' do
      let(:project_alias) { create(:project_alias, project: project) }

      it 'returns the project' do
        expect(described_class.find_project(project_alias.name)).to eq([project, false])
      end
    end

    context 'project_path does not match a project alias' do
      context 'project path matches project full path' do
        it 'returns the project' do
          expect(described_class.find_project(project.full_path)).to eq([project, false])
        end
      end

      context 'project path does not match an existing project full path' do
        it 'returns nil' do
          expect(described_class.find_project('some-project')).to eq([nil, nil])
        end
      end
    end
  end
end

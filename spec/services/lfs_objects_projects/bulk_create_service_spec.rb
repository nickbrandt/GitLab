# frozen_string_literal: true

require 'spec_helper'

describe LfsObjectsProjects::BulkCreateService do
  let(:project) { create(:project) }
  let(:target_project) { create(:project) }
  let(:params) { { target_project: target_project } }

  subject { described_class.new(project, params).execute }

  shared_examples_for 'LFS objects assigned to target project' do
    it 'creates LfsObjectsProject records for the target project' do
      expect { subject }.to change { target_project.lfs_objects.count }
      expect(target_project.lfs_objects).to eq(project.lfs_objects)
    end
  end

  context 'target_project is not associated with any of the LFS objects' do
    before do
      create(:lfs_objects_project, project: project)
      create(:lfs_objects_project, project: project)
    end

    it_behaves_like 'LFS objects assigned to target project'
  end

  context 'target_project already associated with some of the LFS objects' do
    before do
      objects_project = create(:lfs_objects_project, project: project)
      create(:lfs_objects_project, project: target_project, lfs_object: objects_project.lfs_object)
      create(:lfs_objects_project, project: project)
    end

    it_behaves_like 'LFS objects assigned to target project'
  end

  context 'target_project is not passed' do
    let(:params) { {} }

    it 'does not create LfsObjectsProject records for the target project' do
      expect { subject }.not_to change { target_project.lfs_objects.count }
      expect(target_project.lfs_objects).to be_empty
    end
  end
end

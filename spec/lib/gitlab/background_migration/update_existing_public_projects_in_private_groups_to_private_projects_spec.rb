# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects, :migration, schema: 20191029191901 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project) { projects.find_by_name(name) }

  context 'private visibility level' do
    let(:name) { 'private-public' }

    it 'updates the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PRIVATE)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { subject.perform(Gitlab::VisibilityLevel::PRIVATE) }.to change { project.reload.visibility_level }.to(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  context 'internal visibility level' do
    let(:name) { 'internal-public' }

    it 'updates the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::INTERNAL)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { subject.perform(Gitlab::VisibilityLevel::INTERNAL) }.to change { project.reload.visibility_level }.to(Gitlab::VisibilityLevel::INTERNAL)
    end
  end

  context 'public visibility level' do
    let(:name) { 'public-public' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PUBLIC)
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { subject.perform(Gitlab::VisibilityLevel::PUBLIC) }.not_to change { project.reload.visibility_level }
    end
  end

  context 'private project visibility level' do
    let(:name) { 'public-private' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PUBLIC)
      create_project(name, Gitlab::VisibilityLevel::PRIVATE)

      expect { subject.perform(Gitlab::VisibilityLevel::PUBLIC) }.not_to change { project.reload.visibility_level }
    end
  end

  context 'no namespace' do
    let(:name) { 'no-namespace' }

    it 'does not update the project visibility' do
      create_namespace(name, Gitlab::VisibilityLevel::PRIVATE, type: 'User')
      create_project(name, Gitlab::VisibilityLevel::PUBLIC)

      expect { subject.perform(Gitlab::VisibilityLevel::PRIVATE) }.not_to change { project.reload.visibility_level }
    end
  end

  def create_namespace(name, visibility, options = {})
    namespaces.create({
                        name: name,
                        path: name,
                        type: 'Group',
                        visibility_level: visibility
                      }.merge(options))
  end

  def create_project(name, visibility)
    projects.create!(namespace_id: namespaces.find_by_name(name).id,
                     name: name,
                     path: name,
                     visibility_level: visibility)
  end
end

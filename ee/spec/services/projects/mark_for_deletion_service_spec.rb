# frozen_string_literal: true

require 'spec_helper'

describe Projects::MarkForDeletionService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'marking project for deletion' do
    before do
      described_class.new(project, user).execute
    end

    it 'marks project as archived and marked for deletion' do
      expect(Project.unscoped.all).to include(project)

      expect(project.archived).to eq(true)
      expect(project.marked_for_deletion_at).not_to be_nil
      expect(project.deleting_user).to eq(user)
    end
  end

  context 'marking project for deletion once again' do
    let(:deletion_date) { 2.days.ago }

    before do
      project.update(marked_for_deletion_at: deletion_date)
      described_class.new(project, user).execute
    end

    it 'does not change original date' do
      expect(project.marked_for_deletion_at).to eq(deletion_date.to_date)
    end
  end

  context 'audit events' do
    it 'saves audit event' do
      expect { described_class.new(project, user).execute }
        .to change { AuditEvent.count }.by(1)
    end
  end
end

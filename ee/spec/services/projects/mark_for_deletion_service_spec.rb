# frozen_string_literal: true

require 'spec_helper'

describe Projects::MarkForDeletionService do
  let(:user) { create(:user) }
  let(:marked_for_deletion_at) { nil }
  let(:project) do
    create(:project,
      :repository,
      namespace: user.namespace,
      marked_for_deletion_at: marked_for_deletion_at)
  end

  context 'with soft-delete feature turned on' do
    before do
      stub_licensed_features(marking_project_for_deletion: true)
    end

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
      let(:marked_for_deletion_at) { 2.days.ago }

      before do
        described_class.new(project, user).execute
      end

      it 'does not change original date' do
        expect(project.marked_for_deletion_at).to eq(marked_for_deletion_at.to_date)
      end
    end

    context 'audit events' do
      it 'saves audit event' do
        expect { described_class.new(project, user).execute }
          .to change { AuditEvent.count }.by(1)
      end
    end
  end

  context 'with soft-delete feature turned off' do
    context 'marking project for deletion' do
      before do
        described_class.new(project, user).execute
      end

      it 'does not change project attributes' do
        expect(Project.all).to include(project)

        expect(project.archived).to eq(false)
        expect(project.marked_for_deletion_at).to be_nil
        expect(project.deleting_user).to be_nil
      end
    end
  end
end

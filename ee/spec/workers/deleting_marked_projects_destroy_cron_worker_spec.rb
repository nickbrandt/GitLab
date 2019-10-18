# frozen_string_literal: true

require 'spec_helper'

describe DeletingMarkedProjectsDestroyCronWorker do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let(:user) { create(:user)}
    let!(:project_marked_for_deletion) { create(:project, marked_for_deletion_at: 14.days.ago, deleting_user: user) }

    before do
      create(:project)
      create(:project, marked_for_deletion_at: 3.days.ago)
    end

    it 'only schedules to delete projects marked for deletion before number of days from settings' do
      expect(PlannedProjectDestroyWorker).to receive(:perform_async).with(project_marked_for_deletion.id)

      worker.perform
    end

    it 'schedules to delete project marked for deletion exectly before number of days from settings' do
      project_marked_for_deletion.update!(marked_for_deletion_at: 7.days.ago, deleting_user: user)

      expect(PlannedProjectDestroyWorker).to receive(:perform_async).with(project_marked_for_deletion.id)

      worker.perform
    end

    context 'when settings are set to not-default number of days' do
      before do
        create(:project, marked_for_deletion_at: 5.days.ago)
        allow(Gitlab::CurrentSettings).to receive(:deletion_adjourned_period).and_return(4)
      end

      it 'only schedules to delete projects marked for deletion before number of days from settings' do
        expect(PlannedProjectDestroyWorker).to receive(:perform_async).twice

        worker.perform
      end
    end
  end
end

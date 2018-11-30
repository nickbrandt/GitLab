require 'spec_helper'

describe ProjectImportScheduleWorker do
  describe '#perform' do
    it 'schedules an import for a project' do
      import_state = create(:import_state)

      allow_any_instance_of(EE::Project).to receive(:add_import_job).and_return(nil)

      expect do
        subject.perform(import_state.project_id)
      end.to change { import_state.reload.status }.from("none").to("scheduled")
    end

    context 'when project is not found' do
      it 'raises ImportStateNotFound' do
        expect { subject.perform(-1) }.to raise_error(described_class::ImportStateNotFound)
      end
    end

    context 'when project does not have import state' do
      it 'raises ImportStateNotFound' do
        project = create(:project)

        expect { subject.perform(project.id) }.to raise_error(described_class::ImportStateNotFound)
      end
    end
  end
end

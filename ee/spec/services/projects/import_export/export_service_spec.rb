# frozen_string_literal: true

require 'spec_helper'

describe Projects::ImportExport::ExportService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    context 'user can admin project' do
      let_it_be(:project) { create(:project) }
      let(:shared) { project.import_export_shared }

      subject { described_class.new(project, user).execute }

      before do
        project.add_maintainer(user)
      end

      it 'saves the design repo' do
        expect(Gitlab::ImportExport::DesignRepoSaver).to receive(:new).and_call_original

        subject
      end
    end

    context 'project templates' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:subgroup) { create(:group, :private, parent: group) }
      let_it_be(:project_template) { create(:project, group: subgroup) }
      let(:shared) { project_template.import_export_shared }

      subject { described_class.new(project_template, user).execute }

      context 'instance-level custom project templates' do
        before do
          stub_ee_application_setting(custom_project_templates_group_id: subgroup.id)
        end

        it 'succeeds' do
          expect(Gitlab::ImportExport::Saver).to receive(:save).with(exportable: project_template, shared: shared)

          subject
        end
      end

      context 'group-level custom project templates' do
        before do
          group.update(custom_project_templates_group_id: subgroup.id)
        end

        it 'succeeds' do
          expect(Gitlab::ImportExport::Saver).to receive(:save).with(exportable: project_template, shared: shared)

          subject
        end
      end
    end
  end
end

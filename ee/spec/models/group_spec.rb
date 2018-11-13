require 'spec_helper'

describe Group do
  let(:group) { create(:group) }

  it { is_expected.to include_module(EE::Group) }

  describe 'associations' do
    it { is_expected.to have_many(:audit_events).dependent(false) }
    it { is_expected.to belong_to(:file_template_project) }
  end

  describe 'scopes' do
    describe '.with_custom_file_templates' do
      let!(:excluded_group) { create(:group) }
      let(:included_group) { create(:group) }
      let(:project) { create(:project, namespace: included_group) }

      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        included_group.update!(file_template_project: project)
      end

      subject(:relation) { described_class.with_custom_file_templates }

      it { is_expected.to contain_exactly(included_group) }

      it 'preloads everything needed to show a valid checked_file_template_project' do
        group = relation.first

        expect { group.checked_file_template_project }.not_to exceed_query_limit(0)

        expect(group.checked_file_template_project).to be_present
      end
    end
  end

  describe 'states' do
    it { is_expected.to be_ldap_sync_ready }

    context 'after the start transition' do
      it 'sets the last sync timestamp' do
        expect { group.start_ldap_sync }.to change { group.ldap_sync_last_sync_at }
      end
    end

    context 'after the finish transition' do
      it 'sets the state to started' do
        group.start_ldap_sync

        expect(group).to be_ldap_sync_started

        group.finish_ldap_sync
      end

      it 'sets last update and last successful update to the same timestamp' do
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .to eq(group.ldap_sync_last_successful_update_at)
      end

      it 'clears previous error message on success' do
        group.start_ldap_sync
        group.mark_ldap_sync_as_failed('Error')
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_error).to be_nil
      end
    end

    context 'after the fail transition' do
      it 'sets the state to failed' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group).to be_ldap_sync_failed
      end

      it 'sets last update timestamp but not last successful update timestamp' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .not_to eq(group.ldap_sync_last_successful_update_at)
      end
    end
  end

  describe '#mark_ldap_sync_as_failed' do
    it 'sets the state to failed' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Error')

      expect(group).to be_ldap_sync_failed
    end

    it 'sets the error message' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Something went wrong')

      expect(group.ldap_sync_error).to eq('Something went wrong')
    end

    it 'is graceful when current state is not valid for the fail transition' do
      expect(group).to be_ldap_sync_ready
      expect { group.mark_ldap_sync_as_failed('Error') }.not_to raise_error
    end
  end

  describe '#actual_size_limit' do
    let(:group) { build(:group) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the value set globally' do
      expect(group.actual_size_limit).to eq(50)
    end

    it 'returns the value set locally' do
      group.update_attribute(:repository_size_limit, 75)

      expect(group.actual_size_limit).to eq(75)
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      group = create(:group)
      group.update_column(:repository_size_limit, 8.exabytes - 1)

      group.reload

      expect(group.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'project_creation_level' do
    it 'outputs the default one if it is nil' do
      stub_application_setting(default_project_creation: ::EE::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)

      group = create(:group, project_creation_level: nil)

      expect(group.project_creation_level).to eq(Gitlab::CurrentSettings.default_project_creation)
    end
  end

  describe '#file_template_project' do
    it { expect(group.private_methods).to include(:file_template_project) }

    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    it { expect(group.private_methods).to include(:file_template_project) }

    context 'validation' do
      let(:project) { create(:project, namespace: group) }

      it 'is cleared if invalid' do
        invalid_project = create(:project)

        group.file_template_project_id = invalid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to be_nil
      end

      it 'is permitted if valid' do
        valid_project = create(:project, namespace: group)

        group.file_template_project_id = valid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to eq(valid_project.id)
      end
    end
  end

  describe '#checked_file_template_project' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: false)
      end

      it 'returns nil for a valid project' do
        group.file_template_project = valid_project

        is_expected.to be_nil
      end
    end
  end

  describe '#checked_file_template_project_id' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project_id }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns the ID for a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project.id)
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(custom_file_templates_for_namespace: false)
        end

        it 'returns nil for a valid project' do
          group.file_template_project = valid_project

          is_expected.to be_nil
        end
      end
    end
  end

  describe '#latest_vulnerabilities' do
    let(:project) { create(:project, namespace: group) }
    let(:external_project) { create(:project) }
    let(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }

    let!(:old_vuln) { create_vulnerability(project) }
    let!(:new_vuln) { create_vulnerability(project) }
    let!(:external_vuln) { create_vulnerability(external_project) }
    let!(:failed_vuln) { create_vulnerability(project, failed_pipeline) }

    subject { group.latest_vulnerabilities }

    def create_vulnerability(project, pipeline = nil)
      pipeline ||= create(:ci_pipeline, :success, project: project)
      create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project)
    end

    it 'returns vulns only for the latest successful pipelines of projects belonging to the group' do
      is_expected.to contain_exactly(new_vuln)
    end

    context 'with vulnerabilities from other branches' do
      let!(:branch_pipeline) { create(:ci_pipeline, :success, project: project, ref: 'feature-x') }
      let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: project) }

      # TODO: This should actually fail and we must scope vulns
      # per branch as soon as we store them for other branches
      it 'includes vulnerabilities from all branches' do
        is_expected.to contain_exactly(branch_vuln)
      end
    end
  end
end

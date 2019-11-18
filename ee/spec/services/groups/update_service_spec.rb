# frozen_string_literal: true

require 'spec_helper'

describe Groups::UpdateService, '#execute' do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, :public) }

  context 'audit events' do
    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: group.id,
        entity_type: 'Group',
        details: {
          author_name: user.name,
          target_id: group.id,
          target_type: 'Group',
          target_details: group.full_path
        }
      }
    end

    context '#visibility' do
      before do
        group.add_owner(user)
      end

      include_examples 'audit event logging' do
        let(:operation) do
          update_group(group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end
        let(:fail_condition!) do
          allow(group).to receive(:save).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility',
              from: 'Public',
              to: 'Private'
            )
          end
        end
      end
    end
  end

  describe 'changing file_template_project_id' do
    let(:group) { create(:group) }
    let(:valid_project) { create(:project, namespace: group) }
    let(:user) { create(:user) }

    def update_file_template_project_id(id)
      update_group(group, user, file_template_project_id: id)
    end

    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    context 'as a group maintainer' do
      before do
        group.add_maintainer(user)
      end

      it 'does not allow a project to be removed' do
        group.update_columns(file_template_project_id: valid_project.id)

        expect(update_file_template_project_id(nil)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('cannot be changed by you')
      end

      it 'does not allow a project to be set' do
        expect(update_file_template_project_id(valid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('cannot be changed by you')
      end
    end

    context 'as a group owner' do
      before do
        group.add_owner(user)
      end

      it 'allows a project to be removed' do
        group.update_columns(file_template_project_id: valid_project.id)

        expect(update_file_template_project_id(nil)).to be_truthy
        expect(group.reload.file_template_project_id).to be_nil
      end

      it 'allows a valid project to be set' do
        expect(update_file_template_project_id(valid_project.id)).to be_truthy
        expect(group.reload.file_template_project_id).to eq(valid_project.id)
      end

      it 'does not allow a project outwith the group to be set' do
        invalid_project = create(:project)

        expect(update_file_template_project_id(invalid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('is invalid')
      end

      it 'does not allow a non-existent project to be set' do
        invalid_project = create(:project)
        invalid_project.destroy!

        expect(update_file_template_project_id(invalid_project.id)).to be_falsy
        expect(group.errors[:file_template_project_id]).to include('is invalid')
      end

      context 'in a subgroup' do
        let(:parent_group) { create(:group) }
        let(:hidden_project) { create(:project, :private, namespace: parent_group) }
        let(:group) { create(:group, parent: parent_group) }

        before do
          group.update!(parent: parent_group)
        end

        it 'does not allow a project the group owner cannot see to be set' do
          expect(update_file_template_project_id(hidden_project.id)).to be_falsy
          expect(group.reload.file_template_project_id).to be_nil
        end

        it 'allows a project in the subgroup to be set' do
          expect(update_file_template_project_id(valid_project.id)).to be_truthy
          expect(group.reload.file_template_project_id).to eq(valid_project.id)
        end
      end
    end
  end

  context 'with project' do
    let(:project) { create(:project, namespace: group) }

    shared_examples 'with packages' do
      before do
        stub_licensed_features(packages: true)
        group.add_owner(user)
      end

      context 'with npm packages' do
        let!(:package) { create(:npm_package, project: project) }

        it 'does not allow a path update' do
          expect(update_group(group, user, path: 'updated')).to be false
          expect(group.errors[:path]).to include('cannot change when group contains projects with NPM packages')
        end

        it 'allows name update' do
          expect(update_group(group, user, name: 'Updated')).to be true
          expect(group.errors).to be_empty
          expect(group.name).to eq('Updated')
        end
      end
    end

    it_behaves_like 'with packages'

    context 'located in a subgroup' do
      let(:subgroup) { create(:group, parent: group) }
      let!(:project) { create(:project, namespace: subgroup) }

      before do
        subgroup.add_owner(user)
      end

      it_behaves_like 'with packages'

      it 'does allow a path update if there is not a root namespace change' do
        expect(update_group(subgroup, user, path: 'updated')).to be true
        expect(subgroup.errors[:path]).to be_empty
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:group) { create(:group, :public, repository_size_limit: 0) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'converts from MB to Bytes' do
        update_group(group, user, opts)

        expect(group.reload.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        update_group(group, user, opts)

        expect(group.reload.repository_size_limit).to be_nil
      end
    end
  end

  context 'setting ip_restriction' do
    let(:group) { create(:group) }

    subject { update_group(group, user, params) }

    before do
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'when ip_restriction already exists' do
      let!(:ip_restriction) { IpRestriction.create!(group: group, range: '10.0.0.0/8') }

      context 'empty ip restriction param' do
        let(:params) { { ip_restriction_ranges: '' } }

        it 'deletes ip restriction' do
          expect(group.ip_restrictions.first.range).to eql('10.0.0.0/8')

          subject

          expect(group.reload.ip_restrictions.count).to eq(0)
        end
      end
    end
  end

  context 'setting allowed email domain' do
    let(:group) { create(:group) }

    subject { update_group(group, user, params) }

    before do
      stub_licensed_features(group_allowed_email_domains: true)
    end

    context 'when allowed_email_domain already exists' do
      let!(:allowed_domain) { create(:allowed_email_domain, group: group, domain: 'gitlab.com') }

      context 'empty allowed_email_domain param' do
        let(:params) { { allowed_email_domain_attributes: { id: allowed_domain.id, domain: '' } } }

        it 'deletes ip restriction' do
          expect(group.allowed_email_domain.domain).to eql('gitlab.com')

          subject

          expect(group.reload.allowed_email_domain).to be_nil
        end
      end
    end
  end

  context 'updating protected params' do
    let(:attrs) { { shared_runners_minutes_limit: 1000, extra_shared_runners_minutes_limit: 100 } }

    context 'as an admin' do
      let(:user) { create(:admin) }

      it 'updates the attributes' do
        update_group(group, user, attrs)

        expect(group.shared_runners_minutes_limit).to eq(1000)
        expect(group.extra_shared_runners_minutes_limit).to eq(100)
      end
    end

    context 'as a regular user' do
      it 'ignores the attributes' do
        update_group(group, user, attrs)

        expect(group.shared_runners_minutes_limit).to be_nil
        expect(group.extra_shared_runners_minutes_limit).to be_nil
      end
    end
  end

  context 'updating insight_attributes.project_id param' do
    let(:attrs) { { insight_attributes: { project_id: private_project.id } } }

    shared_examples 'successful update of the Insights project' do
      it 'updates the Insights project' do
        update_group(group, user, attrs)

        expect(group.insight.project).to eq(private_project)
      end
    end

    shared_examples 'ignorance of the Insights project ID' do
      it 'ignores the Insights project ID' do
        update_group(group, user, attrs)

        expect(group.insight).to be_nil
      end
    end

    context 'when project is not in the group' do
      let(:private_project) { create(:project, :private) }

      context 'when user can read the project' do
        before do
          private_project.add_maintainer(user)
        end

        it_behaves_like 'ignorance of the Insights project ID'
      end

      context 'when user cannot read the project' do
        it_behaves_like 'ignorance of the Insights project ID'
      end
    end

    context 'when project is in the group' do
      let(:private_project) { create(:project, :private, group: group) }

      context 'when user can read the project' do
        before do
          private_project.add_maintainer(user)
        end

        it_behaves_like 'successful update of the Insights project'
      end

      context 'when user cannot read the project' do
        it_behaves_like 'ignorance of the Insights project ID'
      end
    end
  end

  def update_group(group, user, opts)
    Groups::UpdateService.new(group, user, opts).execute
  end
end

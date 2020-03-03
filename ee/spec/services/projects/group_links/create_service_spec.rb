# frozen_string_literal: true

require 'spec_helper'

describe Projects::GroupLinks::CreateService, '#execute' do
  let(:user) { create :user }
  let(:project) { create :project }
  let(:group) { create(:group, visibility_level: 0) }
  let(:opts) do
    {
      link_group_access: '30',
      expires_at: nil
    }
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { create_group_link(user, project, group, opts) }
      let(:fail_condition!) do
        create(:project_group_link, project: project, group: group)
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: group.id,
           entity_type: 'Group',
           details: {
             add: 'project_access',
             as: 'Developer',
             author_name: user.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end
  end

  context 'when project is in sso enforced group' do
    let(:saml_provider) { create(:saml_provider, enforced_sso: true) }
    let(:root_group) { saml_provider.group }
    let(:project) { create(:project, :private, group: root_group) }
    let(:subject) { described_class.new(project, user, opts) }

    before do
      group_to_invite.add_developer(user)
      stub_licensed_features(group_saml: true)
    end

    context 'when invited group is outside top group' do
      let(:group_to_invite) { create(:group) }

      it 'does not add group to project' do
        expect { subject.execute(group_to_invite) }.not_to change { project.project_group_links.count }
      end
    end

    context 'when invited group is in the top group' do
      let(:group_to_invite) { create(:group, parent: root_group) }

      it 'adds group to project' do
        expect { subject.execute(group_to_invite) }.to change { project.project_group_links.count }.from(0).to(1)
      end
    end

    context 'when project is deeper in the hierarchy and group is in the top group' do
      let(:group_to_invite) { create(:group, parent: root_group) }
      let(:nested_group) { create(:group, parent: root_group) }
      let(:nested_group_2) { create(:group, parent: nested_group_2) }
      let(:project) { create(:project, :private, group: nested_group) }

      it 'adds group to project' do
        expect { subject.execute(group_to_invite) }.to change { project.project_group_links.count }.from(0).to(1)
      end

      context 'when invited group is outside top group' do
        let(:group_to_invite) { create(:group) }

        it 'does not add group to project' do
          expect { subject.execute(group_to_invite) }.not_to change { project.project_group_links.count }
        end
      end
    end
  end

  def create_group_link(user, project, group, opts)
    group.add_developer(user)
    described_class.new(project, user, opts).execute(group)
  end
end

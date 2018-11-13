require 'spec_helper'

describe API::Groups do
  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }
  set(:user) { create(:user) }

  describe 'PUT /groups/:id' do
    before do
      group.add_owner(user)
    end

    subject(:do_it) { put api("/groups/#{group.id}", user), file_template_project_id: project.id }

    it 'does not update file_template_project_id if unlicensed' do
      stub_licensed_features(custom_file_templates_for_namespace: false)

      expect { do_it }.not_to change { group.reload.file_template_project_id }
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).not_to have_key('file_template_project_id')
    end

    it 'updates file_template_project_id if licensed' do
      stub_licensed_features(custom_file_templates_for_namespace: true)

      expect { do_it }.to change { group.reload.file_template_project_id }.to(project.id)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['file_template_project_id']).to eq(project.id)
    end
  end
end

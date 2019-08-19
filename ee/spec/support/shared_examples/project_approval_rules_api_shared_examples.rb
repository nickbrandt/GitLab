# frozen_string_literal: true

shared_examples_for 'an API endpoint for creating project approval rule' do
  let(:current_user) { user }
  let(:params) do
    {
      name: 'security',
      approvals_required: 10
    }
  end

  context 'when missing parameters' do
    it 'returns 400 status' do
      post api(url, current_user)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  context 'when user is without access' do
    it 'returns 403' do
      post api(url, user2), params: params

      expect(response).to have_gitlab_http_status(403)
    end
  end

  context 'when the request is correct' do
    it 'returns 201 status' do
      post api(url, current_user), params: params

      expect(response).to have_gitlab_http_status(201)
      expect(response).to match_response_schema(schema, dir: 'ee')
    end

    it 'changes settings properly' do
      create(:approval_project_rule, project: project, approvals_required: 2)

      project.reset_approvals_on_push = false
      project.disable_overriding_approvers_per_merge_request = true
      project.save

      post api(url, current_user), params: params

      expect(json_response.symbolize_keys).to include(params)
    end

    it 'sets rule_type as report_approver if name matches default name for security reports' do
      expect do
        post api(url, current_user), params: params.merge(name: ApprovalProjectRule::DEFAULT_NAME_FOR_SECURITY_REPORT)
      end.to change { ApprovalProjectRule.report_approver.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(201)
    end
  end
end

shared_examples_for 'an API endpoint for updating project approval rule' do
  shared_examples_for 'a user with access' do
    before do
      project.add_developer(approver)
    end

    context 'when approver already exists' do
      before do
        approval_rule.users << approver
        approval_rule.groups << group
      end

      context 'when sending json data' do
        it 'removes all approvers if empty params are given' do
          expect do
            put api(url, current_user), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
          end.to change { approval_rule.users.count + approval_rule.groups.count }.from(2).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema(schema, dir: 'ee')
        end
      end
    end

    it 'sets approvers' do
      expect do
        put api(url, current_user), params: { users: [approver.id] }
      end.to change { approval_rule.users.count }.from(0).to(1)

      expect(approval_rule.users).to contain_exactly(approver)
      expect(approval_rule.groups).to be_empty

      expect(response).to have_gitlab_http_status(200)
    end
  end

  context 'as a project admin' do
    it_behaves_like 'a user with access' do
      let(:current_user) { user }
      let(:visible_approver_groups_count) { 0 }
    end
  end

  context 'as a global admin' do
    it_behaves_like 'a user with access' do
      let(:current_user) { admin }
      let(:visible_approver_groups_count) { 1 }
    end
  end

  context 'as a random user' do
    it 'returns 403' do
      project.approvers.create(user: approver)

      expect do
        put api(url, user2), params: { users: [], groups: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
      end.not_to change { approval_rule.approvers.size }

      expect(response).to have_gitlab_http_status(403)
    end
  end
end

shared_examples_for 'an API endpoint for deleting project approval rule' do
  it 'destroys' do
    delete api(url, user)

    expect(ApprovalProjectRule.exists?(id: approval_rule.id)).to eq(false)
    expect(response).to have_gitlab_http_status(204)
  end

  context 'when approval rule not found' do
    let!(:approval_rule_2) { create(:approval_project_rule) }
    let(:url) { "/projects/#{project.id}/approval_settings/#{approval_rule_2.id}" }

    it 'returns not found' do
      delete api(url, user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  context 'when user is not eligible to delete' do
    it 'returns forbidden' do
      delete api(url, user2)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end

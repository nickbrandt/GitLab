# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupHooks do
  let(:group_admin) { create(:user) }
  let(:non_admin_user) { create(:user) }
  let(:group) { create(:group) }
  let(:hook_params) { { url: "http://example.com" } }
  let!(:hook) do
    create(:group_hook,
      :all_events_enabled,
      group: group,
      url: 'http://example.com',
      enable_ssl_verification: true)
  end

  def make_all_hooks_request(group_id, user)
    get api("/groups/#{group_id}/hooks", user)
  end

  def make_single_hook_request(group_id, hook_id, user)
    get api("/groups/#{group_id}/hooks/#{hook_id}", user)
  end

  def make_post_group_hook_request(group_id, user, params)
    post api("/groups/#{group_id}/hooks", user), params: params
  end

  def make_put_group_hook_request(group_id, hook_id, user, params)
    put api("/groups/#{group_id}/hooks/#{hook_id}", user), params: params
  end

  def make_delete_group_hook_request(group_id, hook_id, user)
    delete api("/groups/#{group_id}/hooks/#{hook_id}", user)
  end

  before do
    group.add_owner(group_admin)
  end

  describe "GET /groups/:id/hooks" do
    context "authorized user" do
      it "returns group hooks" do
        make_all_hooks_request(group.id, group_admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/group_hooks', dir: 'ee')
      end

      it "returns 404 if group does not exist" do
        make_all_hooks_request(1234, group_admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "authenticated as non admin user" do
      it "does not allow access to group hooks" do
        make_all_hooks_request(group.id, non_admin_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "unauthenticated user" do
      it "does not access group hooks" do
        make_all_hooks_request(group.id, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "GET /groups/:id/hooks/:hook_id" do
    context "authorized user" do
      it "returns a group hook" do
        make_single_hook_request(group.id, hook.id, group_admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/group_hook', dir: 'ee')
      end

      it "returns 404 if hook id is invalid" do
        make_single_hook_request(group.id, 1234, group_admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "authenticated as non admin user" do
      it "does not allow to read single hook" do
        make_single_hook_request(group.id, hook.id, non_admin_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "unauthenticated user" do
      it "does not allow to read single hook" do
        make_single_hook_request(group.id, hook.id, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "POST /groups/:id/hooks" do
    context "authorized user" do
      it "adds a new hook to group" do
        expect do
          make_post_group_hook_request(group.id, group_admin, hook_params)
        end.to change { group.hooks.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/group_hook', dir: 'ee')
      end

      it "returns 400 if url is not given" do
        make_post_group_hook_request(group.id, group_admin, nil)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 422 if url is not valid" do
        make_post_group_hook_request(group.id, group_admin, { url: "ftp://example.com" })

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Invalid url given')
      end

      it "returns 404 if group is not found" do
        make_post_group_hook_request(1234, group_admin, hook_params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "authenticated as non admin user" do
      it "returns forbidden to create a hook" do
        make_post_group_hook_request(group.id, non_admin_user, hook_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "unauthenticated user" do
      it "does not allow to create a hook" do
        make_post_group_hook_request(group.id, nil, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /groups/:id/hooks/:hook_id" do
    context "authorized user" do
      it "updates the hook" do
        make_put_group_hook_request(group.id, hook.id, group_admin, hook_params.merge({ push_events: false }))

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/group_hook', dir: 'ee')
        expect(json_response['push_events']).to eq(false)
      end

      it "returns 422 if url is not valid" do
        make_put_group_hook_request(group.id, hook.id, group_admin, hook_params.merge({ url: "ftp://example.com" }))

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Invalid url given')
      end

      it "returns 400 if url is not given" do
        make_put_group_hook_request(group.id, hook.id, group_admin, { push_events: false })

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns 404 if hook_id is not found" do
        make_put_group_hook_request(group.id, 1234, group_admin, hook_params)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns 404 if group id is not found" do
        make_put_group_hook_request(1234, hook.id, group_admin, hook_params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "authenticated as non admin user" do
      it "returns forbidden to update a hook" do
        make_put_group_hook_request(group.id, hook.id, non_admin_user, hook_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "unauthorized user" do
      it "does not allow to update a hook" do
        make_put_group_hook_request(group.id, hook.id, nil, hook_params)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /groups/:id/hooks/:hook_id" do
    context "authorized user" do
      it "deletes the hook from the group" do
        expect do
          make_delete_group_hook_request(group.id, hook.id, group_admin)
        end.to change { group.hooks.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it "returns 404 when hook id is not given" do
        make_delete_group_hook_request(group.id, nil, group_admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns 404 if hook id is invalid" do
        make_delete_group_hook_request(group.id, 1234, group_admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "returns 404 if group id is invalid" do
        make_delete_group_hook_request(1234, hook.id, group_admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "authenticated as non-admin user" do
      it "returns forbidden" do
        make_delete_group_hook_request(group.id, hook.id, non_admin_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "unauthorized user" do
      it "returns unauthorized" do
        make_delete_group_hook_request(group.id, hook.id, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end

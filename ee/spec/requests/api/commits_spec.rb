# frozen_string_literal: true

require "spec_helper"

describe API::Commits do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user, path: "my.project") }
  let(:project_id) { project.id }

  before do
    project.add_maintainer(user)
  end

  shared_examples_for "returns a 403 from a codeowners violation" do
    let(:error_msg) { "CodeOwners error msg" }

    before do
      allow(ProtectedBranch)
        .to receive(:branch_requires_code_owner_approval?)
        .with(project, branch).and_return(code_owner_approval_required)
    end

    it "creates a new validator with expected parameters" do
      expect(Gitlab::CodeOwners::Validator)
        .to receive(:new).with(project, branch, Array(paths)).and_call_original

      subject
    end

    it "returns 403" do
      expect_next_instance_of(Gitlab::CodeOwners::Validator) do |validator|
        expect(validator).to receive(:execute).and_return(error_msg)
      end

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response["message"]).to include(error_msg)
    end
  end

  describe "POST /projects/:id/repository/commits" do
    let!(:url) { "/projects/#{project_id}/repository/commits" }

    subject(:request) { post api(url, user), params: params }

    context "create" do
      let(:message) { "Created a new file with a very very looooooooooooooooooooooooooooooooooooooooooooooong commit message" }
      let(:valid_c_params) do
        {
          branch: "master",
          commit_message: message,
          actions: [
            {
              action: "create",
              file_path: "foo/bar/baz.txt",
              content: "puts 8"
            }
          ]
        }
      end

      context "a new file that matches a codeowner entry" do
        context "when codeowners are required" do
          it_behaves_like "returns a 403 from a codeowners violation" do
            let(:code_owner_approval_required) { true }
            let(:params) { valid_c_params }
            let(:branch) { valid_c_params[:branch] }
            let(:paths)  { valid_c_params[:actions].first[:file_path] }
          end
        end
      end
    end

    context "delete" do
      let(:message) { "Deleted file" }
      let(:valid_d_params) do
        {
          branch: "markdown",
          commit_message: message,
          actions: [
            {
              action: "delete",
              file_path: "doc/api/users.md"
            }
          ]
        }
      end

      context "a deleted file that matches a codeowner entry" do
        it_behaves_like "returns a 403 from a codeowners violation" do
          let(:code_owner_approval_required) { true }
          let(:params) { valid_d_params }
          let(:branch) { valid_d_params[:branch] }
          let(:paths)  { valid_d_params[:actions].first[:file_path] }
        end
      end
    end

    describe "move" do
      let(:message) { "Moved file" }
      let(:valid_m_params) do
        {
          branch: "feature",
          commit_message: message,
          actions: [
            {
              action: "move",
              file_path: "VERSION.txt",
              previous_path: "VERSION",
              content: "6.7.0.pre"
            }
          ]
        }
      end

      context "a moved file that matches a codeowner entry" do
        it_behaves_like "returns a 403 from a codeowners violation" do
          let(:code_owner_approval_required) { true }
          let(:params) { valid_m_params }
          let(:branch) { valid_m_params[:branch] }
          let(:paths) do
            action = valid_m_params[:actions].first
            [action[:file_path], action[:previous_path]]
          end
        end
      end
    end
  end

  describe 'POST :id/repository/commits/:sha/cherry_pick' do
    let(:commit) { project.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }
    let(:commit_id) { commit.id }
    let(:branch) { 'master' }
    let(:route) { "/projects/#{project_id}/repository/commits/#{commit_id}/cherry_pick" }

    subject(:request) { post api(route, user), params: { branch: branch } }

    context "a file in the cherry-picked commit matches a codeowner entry" do
      context "when codeowners are required" do
        it_behaves_like "returns a 403 from a codeowners violation" do
          let(:code_owner_approval_required) { true }
          let(:paths) { commit.raw_deltas.flat_map { |diff| [diff.new_path, diff.old_path] }.uniq }
        end
      end
    end
  end
end

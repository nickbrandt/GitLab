# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlobController do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }

  shared_examples "file matches a codeowners rule" do
    let(:error_msg) { "Example error msg" }

    it "renders to the edit page with an error msg" do
      default_params[:file_path] = "CHANGELOG"

      expect_next_instance_of(Gitlab::CodeOwners::Validator) do |validator|
        expect(validator).to receive(:execute).and_return(error_msg)
      end

      subject

      expect(flash[:alert]).to eq(error_msg)
      expect(response).to render_template(expected_view)
    end
  end

  describe 'POST create' do
    let(:user) { create(:user) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master',
        branch_name: 'master',
        file_name: 'CHANGELOG',
        content: 'Added changes',
        commit_message: 'Create CHANGELOG'
      }
    end

    before do
      project.add_developer(user)

      sign_in(user)
    end

    it 'redirects to blob' do
      post :create, params: default_params

      expect(response).to be_ok
    end

    it_behaves_like "file matches a codeowners rule" do
      subject { post :create, params: default_params }

      let(:expected_view) { :new }
    end
  end

  describe 'PUT update' do
    let(:user) { create(:user) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG',
        branch_name: 'master',
        content: 'Added changes',
        commit_message: 'Update CHANGELOG'
      }
    end

    def blob_after_edit_path
      project_blob_path(project, 'master/CHANGELOG')
    end

    before do
      project.add_maintainer(user)

      sign_in(user)
    end

    it_behaves_like "file matches a codeowners rule" do
      subject { put :update, params: default_params }

      let(:expected_view) { :edit }
    end
  end
end

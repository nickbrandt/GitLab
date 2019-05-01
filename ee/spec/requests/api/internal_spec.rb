# frozen_string_literal: true
require 'spec_helper'

describe API::Internal do
  describe "POST /internal/allowed" do
    context "for design repositories" do
      set(:user) { create(:user) }
      set(:project) { create(:project) }
      set(:key) { create(:key, user: user) }
      let(:secret_token) { Gitlab::Shell.secret_token }
      let(:gl_repository) { EE::Gitlab::GlRepository::DESIGN.identifier_for_subject(project) }

      it "does not allow access" do
        post(api("/internal/allowed"),
             params: {
               key_id: key.id,
               project: project.full_path,
               gl_repository: gl_repository,
               secret_token: secret_token,
               protocol: 'ssh'
             })

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end

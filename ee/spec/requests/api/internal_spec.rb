# frozen_string_literal: true
require 'spec_helper'

describe API::Internal do
  describe "POST /internal/allowed" do
    set(:user) { create(:user) }
    set(:key) { create(:key, user: user) }
    let(:secret_token) { Gitlab::Shell.secret_token }

    context "for design repositories" do
      set(:project) { create(:project) }
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

    context "project alias" do
      let(:project) { create(:project, :public, :repository) }

      context "without premium license" do
        context "project matches a project alias" do
          let(:project_alias) { create(:project_alias, project: project) }

          before do
            post(
              api("/internal/allowed"),
              params: {
                action: "git-upload-pack",
                key_id: key.id,
                project: project_alias.name,
                protocol: 'ssh',
                secret_token: secret_token
              }
            )
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context "with premium license" do
        before do
          create(:license, plan: License::PREMIUM_PLAN)
        end

        context "project matches a project alias" do
          let(:project_alias) { create(:project_alias, project: project) }

          before do
            post(
              api("/internal/allowed"),
              params: {
                action: "git-upload-pack",
                key_id: key.id,
                project: project_alias.name,
                protocol: 'ssh',
                secret_token: secret_token
              }
            )
          end

          it "allows access" do
            expect(response).to have_gitlab_http_status(200)
          end
        end

        context "project doesn't match a project alias" do
          before do
            post(
              api("/internal/allowed"),
              params: {
                action: "git-upload-pack",
                key_id: key.id,
                project: "some-project",
                protocol: 'ssh',
                secret_token: secret_token
              }
            )
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end
  end
end

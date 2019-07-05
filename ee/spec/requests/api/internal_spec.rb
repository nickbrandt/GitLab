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
      let(:project_alias) { create(:project_alias, project: project) }

      def check_access_by_alias(alias_name)
        post(
          api("/internal/allowed"),
          params: {
            action: "git-upload-pack",
            key_id: key.id,
            project: alias_name,
            protocol: 'ssh',
            secret_token: secret_token
          }
        )
      end

      context "without premium license" do
        context "project matches a project alias" do
          before do
            check_access_by_alias(project_alias.name)
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context "with premium license" do
        before do
          stub_licensed_features(project_aliases: true)
        end

        context "project matches a project alias" do
          before do
            check_access_by_alias(project_alias.name)
          end

          it "allows access" do
            expect(response).to have_gitlab_http_status(200)
          end
        end

        context "project doesn't match a project alias" do
          before do
            check_access_by_alias('some-project')
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end

    context 'smartcard session required' do
      set(:project) { create(:project, :repository, :wiki_repo) }

      subject do
        post(
          api("/internal/allowed"),
          params: { key_id: key.id,
                    project: project.full_path,
                    gl_repository: "project-#{project.id}",
                    action: 'git-upload-pack',
                    secret_token: secret_token,
                    protocol: 'ssh' })
      end

      before do
        stub_licensed_features(smartcard_auth: true)
        stub_smartcard_setting(enabled: true, required_for_git_access: true)

        project.add_developer(user)
      end

      context 'user with a smartcard session', :clean_gitlab_redis_shared_state do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
        end

        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'user without a smartcard session' do
        it "does not allow access" do
          subject

          expect(response).to have_gitlab_http_status(401)
          expect(json_response['message']).to eql('Project requires smartcard login. Please login to GitLab using a smartcard.')
        end
      end

      context 'with the setting off' do
        before do
          stub_smartcard_setting(required_for_git_access: false)
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end
end

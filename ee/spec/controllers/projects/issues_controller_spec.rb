# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssuesController do
  let(:namespace) { create(:group, :public) }
  let(:project)   { create(:project_empty_repo, :public, namespace: namespace) }
  let(:user) { create(:user) }

  describe 'licensed features' do
    let(:project) { create(:project, group: namespace) }
    let(:user) { create(:user) }
    let(:epic) { create(:epic, group: namespace) }
    let(:issue) { create(:issue, project: project, weight: 5) }
    let(:issue2) { create(:issue, project: project, weight: 1) }
    let(:new_issue) { build(:issue, project: project, weight: 5) }

    before do
      namespace.add_developer(user)
      sign_in(user)
    end

    def perform(method, action, opts = {})
      send(method, action, params: opts.merge(namespace_id: project.namespace.to_param, project_id: project.to_param))
    end

    context 'licensed' do
      before do
        stub_licensed_features(issue_weights: true, epics: true, security_dashboard: true)
      end

      describe '#index' do
        it 'allows sorting by weight' do
          expected = [issue, issue2].sort_by(&:weight)

          perform :get, :index, sort: 'weight'

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:issues)).to eq(expected)
        end

        it 'allows filtering by weight' do
          _ = issue
          _ = issue2

          perform :get, :index, weight: 1

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:issues)).to eq([issue2])
        end
      end

      describe '#update' do
        it 'sets issue weight and epic' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6, epic_id: epic.id }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(issue.reload.weight).to eq(6)
          expect(issue.epic).to eq(epic)
        end
      end

      describe '#new' do
        render_views

        context 'when a vulnerability_id is provided' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:finding) { create(:vulnerabilities_finding, pipelines: [pipeline]) }
          let(:vulnerability) { create(:vulnerability, project: project, findings: [finding]) }
          let(:vulnerability_field) { "<input type=\"hidden\" name=\"vulnerability_id\" id=\"vulnerability_id\" value=\"#{vulnerability.id}\" />" }

          subject { get :new, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability.id } }

          it 'sets the vulnerability_id' do
            subject

            expect(response.body).to include(vulnerability_field)
          end

          it 'sets the confidential flag to true by default' do
            subject

            expect(assigns(:issue).confidential).to eq(true)
          end
        end
      end

      describe '#create' do
        it 'sets issue weight and epic' do
          perform :post, :create, issue: new_issue.attributes.merge(epic_id: epic.id)

          expect(response).to have_gitlab_http_status(:found)
          expect(Issue.count).to eq(1)

          issue = Issue.first
          expect(issue.weight).to eq(new_issue.weight)
          expect(issue.epic).to eq(epic)
        end

        context 'when created from a vulnerability' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:finding) { create(:vulnerabilities_finding, pipelines: [pipeline]) }
          let(:vulnerability) { create(:vulnerability, project: project, findings: [finding]) }

          before do
            stub_licensed_features(security_dashboard: true)
          end

          it 'links the issue to the vulnerability' do
            send_request

            expect(project.issues.last.vulnerability_links.first.vulnerability).to eq(vulnerability)
          end

          it 'creates vulnerability feedback' do
            send_request

            expect(project.issues.last).to eq(Vulnerabilities::Feedback.last.issue)
          end

          it 'overwrites the default fields' do
            send_request

            issue = project.issues.last
            expect(issue.title).to eq('Title')
            expect(issue.description).to eq('Description')
            expect(issue.confidential).to be false
          end

          context 'when vulnerability already has a linked issue' do
            render_views

            let!(:vulnerabilities_issue_link) { create(:vulnerabilities_issue_link, :created, vulnerability: vulnerability) }

            it 'shows an error message' do
              send_request

              expect(flash[:alert]).to include('Unable to create link to vulnerability')
              expect(vulnerability.issue_links.map(&:issue)).to eq([vulnerabilities_issue_link.issue])
            end
          end

          private

          def send_request
            post :create, params: {
              namespace_id: project.namespace.to_param,
              project_id: project,
              issue: { title: 'Title', description: 'Description', confidential: 'false' },
              vulnerability_id: vulnerability.id
            }
          end
        end
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(issue_weights: false, epics: false, security_dashboard: false)
      end

      describe '#index' do
        it 'ignores filtering by weight' do
          expected = [issue, issue2]

          perform :get, :index, weight: 1

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:issues)).to match_array(expected)
        end
      end

      describe '#update' do
        it 'does not set issue weight' do
          perform :put, :update, id: issue.to_param, issue: { weight: 6 }, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(issue.reload.weight).to be_nil
          expect(issue.reload.read_attribute(:weight)).to eq(5) # pre-existing data is not overwritten
        end
      end

      describe '#new' do
        render_views

        context 'when a vulnerability_id is provided' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:finding) { create(:vulnerabilities_finding, pipelines: [pipeline]) }
          let(:vulnerability) { create(:vulnerability, project: project, findings: [finding]) }
          let(:vulnerability_field) { "<input type=\"hidden\" name=\"vulnerability_id\" id=\"vulnerability_id\" value=\"#{vulnerability.id}\" />" }

          it 'does not build issue from a vulnerability' do
            get :new, params: { namespace_id: project.namespace, project_id: project, vulnerability_id: vulnerability.id }

            expect(response.body).not_to include(vulnerability_field)
            expect(issue.description).to be_nil
          end
        end
      end

      describe '#create' do
        it 'does not set issue weight ane epic' do
          perform :post, :create, issue: new_issue.attributes

          expect(response).to have_gitlab_http_status(:found)
          expect(Issue.count).to eq(1)

          issue = Issue.first
          expect(issue.weight).to be_nil
          expect(issue.epic).to be_nil
        end
      end
    end
  end

  describe 'GET #discussions' do
    let(:issue) { create(:issue, project: project) }
    let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

    context 'with a related system note' do
      let(:confidential_issue) { create(:issue, :confidential, project: project) }
      let!(:system_note) { SystemNoteService.relate_issue(issue, confidential_issue, user) }

      shared_examples 'user can see confidential issue' do |access_level|
        context "when a user is a #{access_level}" do
          before do
            project.add_user(user, access_level)
          end

          it 'displays related notes' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            discussions = json_response
            notes = discussions.flat_map {|d| d['notes']}

            expect(discussions.count).to equal(2)
            expect(notes).to include(a_hash_including('id' => system_note.id.to_s))
          end
        end
      end

      shared_examples 'user cannot see confidential issue' do |access_level|
        context "when a user is a #{access_level}" do
          before do
            project.add_user(user, access_level)
          end

          it 'redacts note related to a confidential issue' do
            get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid }

            discussions = json_response
            notes = discussions.flat_map {|d| d['notes']}

            expect(discussions.count).to equal(1)
            expect(notes).not_to include(a_hash_including('id' => system_note.id.to_s))
          end
        end
      end

      context 'when authenticated' do
        before do
          sign_in(user)
        end

        %i(reporter developer maintainer).each do |access|
          it_behaves_like 'user can see confidential issue', access
        end

        it_behaves_like 'user cannot see confidential issue', :guest
      end

      context 'when unauthenticated' do
        let(:project) { create(:project, :public) }

        it_behaves_like 'user cannot see confidential issue', Gitlab::Access::NO_ACCESS
      end
    end

    context 'is_gitlab_employee attribute' do
      subject { get :discussions, params: { namespace_id: project.namespace, project_id: project, id: issue.iid } }

      before do
        sign_in(user)
        allow(Gitlab).to receive(:com?).and_return(true)
        discussion.update!(author: user)
      end

      shared_context 'non inclusion of gitlab team member badge' do |result|
        it 'does not render the is_gitlab_employee attribute' do
          subject

          note_json = json_response.first['notes'].first

          expect(note_json['author']['is_gitlab_employee']).to be result
        end
      end

      context 'when user is a gitlab team member' do
        include_context 'gitlab team member'

        it 'renders the is_gitlab_employee attribute' do
          subject

          note_json = json_response.first['notes'].first

          expect(note_json['author']['is_gitlab_employee']).to be true
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(gitlab_employee_badge: false)
          end

          it_behaves_like 'non inclusion of gitlab team member badge', nil
        end
      end

      context 'when user is not a gitlab team member' do
        it_behaves_like 'non inclusion of gitlab team member badge', false

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(gitlab_employee_badge: false)
          end

          it_behaves_like 'non inclusion of gitlab team member badge', nil
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:issue) { create(:issue, project: project) }

    def update_issue(issue_params: {}, additional_params: {}, id: nil)
      id ||= issue.iid
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: id,
        issue: { title: 'New title' }.merge(issue_params),
        format: :json
      }.merge(additional_params)

      put :update, params: params
    end

    context 'changing the assignee' do
      let(:assignee) { create(:user) }

      before do
        project.add_developer(assignee)
        sign_in(assignee)
      end

      context 'when the gitlab_employee_badge flag is off' do
        it 'does not expose the is_gitlab_employee attribute on the assignee' do
          stub_feature_flags(gitlab_employee_badge: false)

          update_issue(issue_params: { assignee_ids: [assignee.id] })

          expect(json_response['assignees'].first.keys)
            .to match_array(%w(id name username avatar_url state web_url))
        end
      end

      context 'when the gitlab_employee_badge flag is on but we are not on gitlab.com' do
        it 'does not expose the is_gitlab_employee attribute on the assignee' do
          stub_feature_flags(gitlab_employee_badge: true)
          allow(Gitlab).to receive(:com?).and_return(false)

          update_issue(issue_params: { assignee_ids: [assignee.id] })

          expect(json_response['assignees'].first.keys)
            .to match_array(%w(id name username avatar_url state web_url))
        end
      end

      context 'when the gitlab_employee_badge flag is on and we are on gitlab.com' do
        it 'exposes the is_gitlab_employee attribute on the assignee' do
          stub_feature_flags(gitlab_employee_badge: true)
          allow(Gitlab).to receive(:com?).and_return(true)

          update_issue(issue_params: { assignee_ids: [assignee.id] })

          expect(json_response['assignees'].first.keys)
            .to match_array(%w(id name username avatar_url state web_url is_gitlab_employee))
        end
      end
    end
  end

  it_behaves_like DescriptionDiffActions do
    let_it_be(:project)  { create(:project_empty_repo, :public) }
    let_it_be(:issuable) { create(:issue, project: project) }
  end
end

# frozen_string_literal: true

require "spec_helper"

describe 'EE-specific project routing' do
  before do
    allow(Project).to receive(:find_by_full_path).with('gitlab/gitlabhq', any_args).and_return(true)
  end

  # project_vulnerability_feedback  GET    /:project_id/vulnerability_feedback(.:format)     projects/vulnerability_feedback#index
  #                                 POST   /:project_id/vulnerability_feedback(.:format)     projects/vulnerability_feedback#create
  # project_vulnerability_feedback  DELETE /:project_id/vulnerability_feedback/:id(.:format) projects/vulnerability_feedback#destroy
  describe Projects::VulnerabilityFeedbackController, 'routing', type: :routing do
    it "to #index" do
      expect(get("/gitlab/gitlabhq/vulnerability_feedback")).to route_to('projects/vulnerability_feedback#index', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it "to #create" do
      expect(post("/gitlab/gitlabhq/vulnerability_feedback")).to route_to('projects/vulnerability_feedback#create', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end

    it "to #destroy" do
      expect(delete("/gitlab/gitlabhq/vulnerability_feedback/1")).to route_to('projects/vulnerability_feedback#destroy', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1')
    end
  end

  # security_namespace_project_pipeline GET /:project_id/pipelines/:id/security(.:format)
  describe Projects::PipelinesController, 'routing' do
    it 'to #security' do
      expect(get('/gitlab/gitlabhq/pipelines/12/security')).to route_to('projects/pipelines#security', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '12')
    end
  end

  describe Projects::DesignsController, 'routing' do
    it 'to #show' do
      expect(get('/gitlab/gitlabhq/-/designs/1/master')).to route_to('projects/designs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', ref: 'master')
      expect(get('/gitlab/gitlabhq/-/designs/1/my/branch')).to route_to('projects/designs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', ref: 'my/branch')
      expect(get('/gitlab/gitlabhq/-/designs/1/f166f5c7afaed9e1236e4e5965585f235795db4c3f45e8a9f6ea9dde098c')).to route_to('projects/designs#show', namespace_id: 'gitlab', project_id: 'gitlabhq', id: '1', ref: 'f166f5c7afaed9e1236e4e5965585f235795db4c3f45e8a9f6ea9dde098c')
    end
  end

  describe Projects::AutocompleteSourcesController, 'routing' do
    it "to #epics" do
      expect(get("/gitlab/gitlabhq/-/autocomplete_sources/epics")).to route_to("projects/autocomplete_sources#epics", namespace_id: 'gitlab', project_id: 'gitlabhq')
    end
  end

  describe Projects::Settings::OperationsController, 'routing' do
    it 'to #reset_alerting_token' do
      expect(post('/gitlab/gitlabhq/-/settings/operations/reset_alerting_token')).to route_to('projects/settings/operations#reset_alerting_token', namespace_id: 'gitlab', project_id: 'gitlabhq')
    end
  end

  describe Projects::ProtectedEnvironmentsController, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/protected_environments", "/gitlab/gitlabhq/-/protected_environments"
    end
  end

  describe Projects::AuditEventsController, 'routing' do
    describe 'legacy routing' do
      it_behaves_like 'redirecting a legacy project path', "/gitlab/gitlabhq/audit_events", "/gitlab/gitlabhq/-/audit_events"
    end
  end
end

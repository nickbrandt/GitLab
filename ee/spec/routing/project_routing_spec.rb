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
end

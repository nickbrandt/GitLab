require 'rails_helper'

describe CycleAnalytics::ProjectStage do
  it_behaves_like "cycle analytics stage" do
    let(:parent) { create(:project) }
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:project) { create(:project) }
      let(:factory) { :cycle_analytics_project_stage }
      let(:default_params) { { project: project } }
    end
  end
end

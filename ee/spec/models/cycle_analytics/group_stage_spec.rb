require 'rails_helper'

describe CycleAnalytics::GroupStage do
  it_behaves_like "cycle analytics stage" do
    let(:parent) { create(:group) }
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:group) { create(:group) }
      let(:factory) { :cycle_analytics_group_stage }
      let(:default_params) { { group: group } }
    end
  end
end

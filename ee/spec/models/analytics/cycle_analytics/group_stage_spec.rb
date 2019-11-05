# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::GroupStage do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end

  it_behaves_like 'cycle analytics stage' do
    let(:parent) { create(:group) }
    let(:parent_name) { :group }
  end

  context 'relative positioning' do
    it_behaves_like 'a class that supports relative positioning' do
      let(:group) { create(:group) }
      let(:factory) { :cycle_analytics_group_stage }
      let(:default_params) { { group: group } }
    end
  end
end

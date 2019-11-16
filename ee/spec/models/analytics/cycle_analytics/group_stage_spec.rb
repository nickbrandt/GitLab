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

  include_examples 'cycle analytics label based stage' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:parent_in_subgroup) { create(:group, parent: parent) }
    let_it_be(:group_label) { create(:group_label, group: parent) }
    let_it_be(:parent_outside_of_group_label_scope) { create(:group) }
  end

  context 'relative positioning' do
    it_behaves_like 'a class that supports relative positioning' do
      let(:parent) { create(:group) }
      let(:factory) { :cycle_analytics_group_stage }
      let(:default_params) { { group: parent } }
    end
  end
end

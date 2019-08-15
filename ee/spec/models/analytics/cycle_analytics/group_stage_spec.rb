# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::GroupStage do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe '[EE] Public Group access' do
  include AccessMatchers

  set(:group)   { create(:group, :public) }
  set(:project) { create(:project, :public, group: group) }
  set(:project_guest) do
    create(:user) do |user|
      project.add_guest(user)
    end
  end

  describe 'GET /groups/:path/-/insights' do
    before do
      stub_licensed_features(insights: true)
    end

    subject { group_insights_path(group) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:auditor) }
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_allowed_for(:external) }
    it { is_expected.to be_allowed_for(:visitor) }
  end
end

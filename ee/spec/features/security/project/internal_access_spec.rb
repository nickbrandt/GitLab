# frozen_string_literal: true

require 'spec_helper'

describe '[EE] Internal Project Access' do
  include AccessMatchers

  set(:project) { create(:project, :internal, :repository) }

  describe 'GET /:project_path/insights' do
    before do
      stub_licensed_features(insights: true)
    end

    subject { project_insights_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:auditor) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end
end

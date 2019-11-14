# frozen_string_literal: true

require 'spec_helper'

describe Ci::Subscriptions::Project do
  let!(:subscription) { create(:ci_subscriptions_project) }

  describe 'Relations' do
    it { is_expected.to belong_to(:downstream_project).required }
    it { is_expected.to belong_to(:upstream_project).required }
  end

  describe 'Validations' do
    it { is_expected.to validate_uniqueness_of(:upstream_project_id).scoped_to(:downstream_project_id) }

    it 'validates that upstream project is public' do
      subscription.upstream_project.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      expect(subscription).not_to be_valid
    end
  end
end

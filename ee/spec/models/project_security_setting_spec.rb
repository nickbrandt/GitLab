# frozen_string_literal: true

require 'spec_helper'

describe ProjectSecuritySetting do
  subject { create(:project_security_setting) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end
end

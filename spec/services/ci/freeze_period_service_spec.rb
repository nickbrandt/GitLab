# frozen_string_literal: true

require 'spec_helper'

describe Ci::FreezePeriodService do

  let!(:freeze_period) { create :project_deploy_freeze_period }
  subject { described_class.new(project_id: freeze_period.project_id).execute }

  context 'when outside freeze period' do
    it 'is not frozen' do
      expect(subject).to be_falsy
    end
  end
end
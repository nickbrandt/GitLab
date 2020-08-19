# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IncidentData, type: :model do
  let_it_be(:project) { create(:project) }
  let_it_be(:incident_data) { create(:incident_data, project: project) }

  subject { incident_data }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
  end

  describe 'enums' do
    let(:severity_values) do
      { unknown: 0, low: 1, medium: 2, high: 3, critical: 4 }
    end

    it { is_expected.to define_enum_for(:severity).with_values(severity_values) }
  end
end

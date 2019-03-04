# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Feedback do
  it { is_expected.to define_enum_for(:feedback_type) }
  it { is_expected.to define_enum_for(:category) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline').with_foreign_key('pipeline_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:feedback_type) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }
  end
end

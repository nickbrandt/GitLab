# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExperimentSubject, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:experiment) }
  end

  describe 'validate must_have_at_least_one_subject' do
    let(:experiment_subject) { build(:experiment_subject, user: nil, group: nil, project: nil) }

    it 'fails if user, group, & project are blank' do
      expect(experiment_subject).not_to be_valid
      expect(experiment_subject.errors[:base]).to include("Must have at least one of User, Group, or Project.")
    end

    it 'passes when user is present' do
      experiment_subject.user = build(:user)
      expect(experiment_subject).to be_valid
    end

    it 'passes when group is present' do
      experiment_subject.group = build(:group)
      expect(experiment_subject).to be_valid
    end

    it 'passes when project is present' do
      experiment_subject.project = build(:project)
      expect(experiment_subject).to be_valid
    end

    it 'passes when multiple subjects are present' do
      experiment_subject.user = build(:user)
      experiment_subject.group = build(:group)
      experiment_subject.project = build(:project)
      expect(experiment_subject).to be_valid
    end
  end
end

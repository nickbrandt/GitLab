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

    describe 'must_have_one_subject_present' do
      let(:experiment_subject) { build(:experiment_subject, subject: nil) }
      let(:error_message) { 'Must have exactly one of User, Group, or Project.' }

      it 'fails when no subject is present' do
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end

      it 'passes when user subject is present' do
        experiment_subject.user = build(:user)
        expect(experiment_subject).to be_valid
      end

      it 'passes when group subject is present' do
        experiment_subject.group = build(:group)
        expect(experiment_subject).to be_valid
      end

      it 'passes when project subject is present' do
        experiment_subject.project = build(:project)
        expect(experiment_subject).to be_valid
      end

      it 'fails when more than one subject is present', :aggregate_failures do
        # two subjects
        experiment_subject.user = build(:user)
        experiment_subject.group = build(:group)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)

        # three subjects
        experiment_subject.project = build(:project)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end
    end
  end

  describe '.find_by_subject' do
    let_it_be(:target_subject) { create(:user) }

    subject { described_class.find_by_subject(target_subject) }

    context 'when a record exists for the given subject' do
      let!(:existing_exp_subj) { create(:experiment_subject, subject: target_subject) }

      it { is_expected.to eq(existing_exp_subj) }
    end

    context 'when no record exists for the given subject' do
      it { is_expected.to be_nil }
    end

    context 'when the given subject is not an expected subject type' do
      let(:target_subject) { create(:issue) }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'used with another scope' do
      let_it_be(:target_subject) { create(:project) }
      let_it_be(:experiment1) { create(:experiment) }
      let_it_be(:experiment2) { create(:experiment) }
      let_it_be(:experiment3) { create(:experiment) }
      let_it_be(:experiment1_subject) { create(:experiment_subject, experiment: experiment1, subject: target_subject) }
      let_it_be(:experiment2_subject) { create(:experiment_subject, experiment: experiment2, subject: target_subject) }

      it 'finds the correct record for experiment1' do
        record = experiment1.experiment_subjects.find_by_subject(target_subject)
        expect(record).to eq(experiment1_subject)
      end

      it 'finds the correct record for experiment2' do
        record = experiment2.experiment_subjects.find_by_subject(target_subject)
        expect(record).to eq(experiment2_subject)
      end

      it 'returns nil for experiment3' do
        record = experiment3.experiment_subjects.find_by_subject(target_subject)
        expect(record).to be_nil
      end
    end
  end

  describe '.find_or_initialize_by_subject' do
    let_it_be(:target_subject) { create(:group) }

    subject { described_class.find_or_initialize_by_subject(target_subject) }

    context 'when a record exists for the given subject' do
      let!(:existing_exp_subj) { create(:experiment_subject, subject: target_subject) }

      it 'returns the existing record' do
        is_expected.not_to be_a_new_record
        is_expected.to eq(existing_exp_subj)
      end
    end

    context 'when no record exists for the given subject' do
      it 'initializes a new record with the given subject' do
        is_expected.to be_a_new_record
        expect(subject.subject).to eq(target_subject)
      end
    end

    context 'when the given subject is not an expected subject type' do
      let(:target_subject) { create(:issue) }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'used with another scope' do
      let_it_be(:target_subject) { create(:project) }
      let_it_be(:experiment1) { create(:experiment) }
      let_it_be(:experiment2) { create(:experiment) }
      let_it_be(:experiment3) { create(:experiment) }
      let_it_be(:experiment1_subject) { create(:experiment_subject, experiment: experiment1, subject: target_subject) }
      let_it_be(:experiment2_subject) { create(:experiment_subject, experiment: experiment2, subject: target_subject) }

      it 'finds the correct record for experiment1' do
        record = experiment1.experiment_subjects.find_or_initialize_by_subject(target_subject)
        expect(record).to eq(experiment1_subject)
      end

      it 'finds the correct record for experiment2' do
        record = experiment2.experiment_subjects.find_or_initialize_by_subject(target_subject)
        expect(record).to eq(experiment2_subject)
      end

      it 'initializes a new record for experiment3' do
        record = experiment3.experiment_subjects.find_or_initialize_by_subject(target_subject)
        expect(record).to be_a_new_record
        expect(record.experiment).to eq(experiment3)
        expect(record.subject).to eq(target_subject)
      end
    end
  end

  describe '.parameterized_subject' do
    subject { described_class.send(:parameterized_subject, target_subject) }

    context 'when given a non-ActiveRecord-like object' do
      let(:target_subject) { nil }

      it 'throws an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when given an ActiveRecord-like object' do
      let(:target_subject) { build(:group) }

      it 'keys the subject with its param_key' do
        is_expected.to eq({ group: target_subject })
      end
    end
  end

  describe '#subject' do
    subject { experiment_subject.subject }

    context 'when there is a subject' do
      let(:experiment_subject) { build(:experiment_subject) }

      it { is_expected.not_to be_nil }
    end

    context 'when there is no subject' do
      let(:experiment_subject) { build(:experiment_subject, subject: nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#subject=' do
    let(:experiment_subject) { build(:experiment_subject) }

    subject { experiment_subject.subject = target_subject }

    context 'when an expected subject type is given' do
      let(:target_subject) { build(:group) }

      it 'associates it to the desired subject' do
        expect { subject }.to change { experiment_subject.group.nil? }.from(true)
      end

      it 'dis-associates any previously set subject' do
        expect { subject }.to change { experiment_subject.user.nil? }.from(false)
      end
    end

    context 'when an unexpected subject type is given' do
      let(:target_subject) { build(:issue) }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      end
    end

    context 'when nil is given' do
      let(:target_subject) { nil }

      it 'clears any existing subject' do
        expect { subject }.to change { experiment_subject.subject.nil? }.from(false)
      end
    end
  end
end

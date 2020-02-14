# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CycleAnalytics::RequestParams do
  let(:params) { { created_after: '2019-01-01', created_before: '2019-03-01' } }

  subject { described_class.new(params) }

  describe 'validations' do
    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'when `created_before` is missing' do
      before do
        params[:created_before] = nil
      end

      it 'is valid' do
        Timecop.travel '2019-03-01' do
          expect(subject).to be_valid
        end
      end
    end

    context 'when `created_before` is earlier than `created_after`' do
      before do
        params[:created_before] = '2015-01-01'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:created_before]).not_to be_empty
      end
    end

    context 'when the date range exceeds 180 days' do
      before do
        params[:created_before] = '2019-07-15'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:created_after]).to include(s_('CycleAnalytics|The given date range is larger than 180 days'))
      end
    end
  end

  it 'casts `created_after` to date' do
    expect(subject.created_after).to be_a_kind_of(Date)
  end

  it 'casts `created_before` to date' do
    expect(subject.created_before).to be_a_kind_of(Date)
  end

  describe 'optional `project_ids`' do
    it { expect(subject.project_ids).to eq([]) }

    context 'when `project_ids` is not empty' do
      let(:project_ids) { [1, 2, 3] }

      before do
        params[:project_ids] = project_ids
      end

      it { expect(subject.project_ids).to eq(project_ids) }
    end

    context 'when `project_ids` is not an array' do
      before do
        params[:project_ids] = 1
      end

      it { expect(subject.project_ids).to eq([1]) }
    end

    context 'when `project_ids` is nil' do
      before do
        params[:project_ids] = nil
      end

      it { expect(subject.project_ids).to eq([]) }
    end
  end

  describe 'optional `group_id`' do
    it { expect(subject.group).to be_nil }

    context 'when `group_id` is not empty' do
      let(:group_id) { 'ca-test-group' }

      before do
        params[:group] = group_id
      end

      it { expect(subject.group).to eq(group_id) }
    end

    context 'when `group_id` is nil' do
      before do
        params[:group] = nil
      end

      it { expect(subject.group).to eq(nil) }
    end
  end
end

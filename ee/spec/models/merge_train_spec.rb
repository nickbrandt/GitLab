# frozen_string_literal: true

require "spec_helper"

describe MergeTrain do
  include ProjectForksHelper

  set(:project) { create(:project, :repository) }

  it { is_expected.to belong_to(:merge_request) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:pipeline) }

  before do
    allow(AutoMergeProcessWorker).to receive(:perform_async)
  end

  describe '.all_in_train' do
    subject { described_class.all_in_train(merge_request) }

    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq([merge_request])
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge request' do
        is_expected.to eq([merge_request, merge_request_2])
      end
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.first_in_train' do
    subject { described_class.first_in_train(merge_request) }

    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq(merge_request)
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge request' do
        is_expected.to eq(merge_request)
      end
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be_nil
      end
    end
  end

  describe '.first_in_trains' do
    let!(:first_on_master) { create_merge_request_on_train(target_branch: 'master', source_branch: 'feature-1') }
    let!(:second_on_master) { create_merge_request_on_train(target_branch: 'master', source_branch: 'feature-2') }

    let!(:first_on_stable) { create_merge_request_on_train(target_branch: 'stable', source_branch: 'feature-1-backport') }
    let!(:second_on_stable) { create_merge_request_on_train(target_branch: 'stable', source_branch: 'feature-2-backport') }

    subject { described_class.first_in_trains(project) }

    it 'returns only first merge requests per merge train' do
      is_expected.to contain_exactly(first_on_master, first_on_stable)
    end
  end

  describe '.first_in_train_from' do
    subject { described_class.first_in_train_from(merge_request_ids) }

    context 'when arguments is null' do
      let(:merge_request_ids) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'when there are two merge requests on the same merge train' do
      let(:merge_request_ids) { [merge_request_1.id, merge_request_2.id] }
      let!(:merge_request_1) { create_merge_request_on_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the first merge request on the merge train from the given ids' do
        is_expected.to eq(merge_request_1)
      end

      context "when specifies merge request 2's id only" do
        let(:merge_request_ids) { [merge_request_2.id] }

        it 'returns the first merge request on the merge train from the given ids' do
          is_expected.to eq(merge_request_2)
        end
      end
    end
  end

  describe '.total_count_in_train' do
    subject { described_class.total_count_in_train(merge_request) }

    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq(1)
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge request' do
        is_expected.to eq(2)
      end
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be(0)
      end
    end
  end

  describe '#all_next' do
    subject { merge_train.all_next }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    it 'returns nil' do
      is_expected.to be_empty
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge requests' do
        is_expected.to eq([merge_request_2])
      end
    end
  end

  describe '#all_prev' do
    subject { merge_train.all_prev }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at first on the train' do
      it 'returns nil' do
        is_expected.to be_empty
      end
    end

    context 'when the merge request is at last on the train' do
      let(:merge_train) { merge_request_2.merge_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the previous merge requests' do
        is_expected.to eq([merge_request])
      end
    end
  end

  describe '#next' do
    subject { merge_train.next }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at last on the train' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge request' do
        is_expected.to eq(merge_request_2)
      end
    end
  end

  describe '#prev' do
    subject { merge_train.prev }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at first on the train' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the merge request is at last on the train' do
      let(:merge_train) { merge_request_2.merge_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge request' do
        is_expected.to eq(merge_request)
      end
    end
  end

  describe '#first_in_train?' do
    subject { merge_train.first_in_train? }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    it { is_expected.to be_truthy }

    context 'when the other merge request is on the merge train' do
      let(:merge_train) { merge_request_2.merge_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#follower_in_train?' do
    subject { merge_train.follower_in_train? }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    it { is_expected.to be_falsy }

    context 'when the other merge request is on the merge train' do
      let(:merge_train) { merge_request_2.merge_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it { is_expected.to be_truthy }
    end
  end

  describe '#index' do
    subject { merge_train.index }

    let(:merge_train) { merge_request.merge_train }
    let!(:merge_request) { create_merge_request_on_train }

    it { is_expected.to eq(0) }

    context 'when the merge train is at the second queue' do
      let(:merge_train) { merge_request_2.merge_train }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it { is_expected.to eq(1) }
    end
  end

  def create_merge_request_on_train(target_project: project, target_branch: 'master', source_project: project, source_branch: 'feature')
    create(:merge_request,
      :on_train,
      target_branch: target_branch,
      target_project: target_project,
      source_branch: source_branch,
      source_project: source_project)
  end
end

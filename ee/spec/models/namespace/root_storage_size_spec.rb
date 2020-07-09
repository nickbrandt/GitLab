# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::RootStorageSize, type: :model do
  let(:namespace) { create(:namespace) }
  let(:current_size) { 50.megabytes }
  let(:limit) { 100 }
  let(:model) { described_class.new(namespace) }
  let(:create_statistics) { create(:namespace_root_storage_statistics, namespace: namespace, storage_size: current_size)}
  let_it_be(:gold_plan, reload: true) { create(:gold_plan) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, plan: gold_plan, storage_size_limit: 100) }
  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan) }

  before do
    create_statistics

    stub_application_setting(namespace_storage_size_limit: limit)
  end

  describe '#above_size_limit?' do
    subject { model.above_size_limit? }

    context 'when limit is 0' do
      let(:limit) { 0 }

      it { is_expected.to eq(false) }
    end

    context 'when below limit' do
      it { is_expected.to eq(false) }
    end

    context 'when above limit' do
      let(:current_size) { 101.megabytes }

      it { is_expected.to eq(true) }
    end
  end

  describe '#usage_ratio' do
    subject { model.usage_ratio }

    it { is_expected.to eq(0.5) }

    context 'when limit is 0' do
      before do
        plan_limits.update!(storage_size_limit: 0)
      end

      it { is_expected.to eq(0) }
    end

    context 'when there are no root_storage_statistics' do
      let(:create_statistics) { nil }

      it { is_expected.to eq(0) }
    end
  end

  describe '#current_size' do
    subject { model.current_size }

    it { is_expected.to eq(current_size) }
  end

  describe '#limit' do
    subject { model.limit }

    context 'when there is additional purchased storage and a plan' do
      before do
        plan_limits.update!(storage_size_limit: 15_000)
        namespace.update!(additional_purchased_storage_size: 10_000)
      end

      it { is_expected.to eq(25_000.megabytes) }
    end

    context 'when there is no additionl purchased storage' do
      before do
        plan_limits.update!(storage_size_limit: 15_000)
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(15_000.megabytes) }
    end

    context 'when there is no additional purchased storage or plan limit set' do
      before do
        plan_limits.update!(storage_size_limit: 0)
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(0) }
    end
  end
end

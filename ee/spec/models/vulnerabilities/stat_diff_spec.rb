# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StatDiff do
  let!(:vulnerability) { create(:vulnerability, :detected, severity: :high, title: 'Title') }
  let(:stat_diff) { described_class.new(vulnerability) }
  let(:update_vulnerability) {}

  describe '#update_required?' do
    subject(:update_required?) { update_vulnerability.then { stat_diff.update_required? } }

    context 'when the vulnerability is destroyed' do
      let(:update_vulnerability) { vulnerability.destroy! }

      it { is_expected.to be_truthy }
    end

    context 'when the vulnerability is not destroyed' do
      context 'when the severity is changed' do
        let(:update_vulnerability) { vulnerability.update_attribute(:severity, :critical) }

        it { is_expected.to be_truthy }
      end

      context 'when the severity is not changed' do
        context 'when the state is changed' do
          shared_examples 'state changes' do |from:, to:, is_update_required:|
            let(:update_vulnerability) { vulnerability.update_attribute(:state, to) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(is_update_required) }
          end

          it_behaves_like 'state changes', from: 'confirmed', to: 'detected', is_update_required: false
          it_behaves_like 'state changes', from: 'confirmed', to: 'resolved', is_update_required: true
          it_behaves_like 'state changes', from: 'confirmed', to: 'dismissed', is_update_required: true

          it_behaves_like 'state changes', from: 'detected', to: 'confirmed', is_update_required: false
          it_behaves_like 'state changes', from: 'detected', to: 'resolved', is_update_required: true
          it_behaves_like 'state changes', from: 'detected', to: 'dismissed', is_update_required: true

          it_behaves_like 'state changes', from: 'resolved', to: 'dismissed', is_update_required: false
          it_behaves_like 'state changes', from: 'resolved', to: 'confirmed', is_update_required: true
          it_behaves_like 'state changes', from: 'resolved', to: 'detected', is_update_required: true

          it_behaves_like 'state changes', from: 'dismissed', to: 'resolved', is_update_required: false
          it_behaves_like 'state changes', from: 'dismissed', to: 'confirmed', is_update_required: true
          it_behaves_like 'state changes', from: 'dismissed', to: 'detected', is_update_required: true
        end

        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:title, 'New Title') }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#changes' do
    subject(:changes) { update_vulnerability.then { stat_diff.changes } }

    context 'when the vulnerability is destroyed' do
      let(:update_vulnerability) { vulnerability.destroy! }
      let(:expected_changes) { { 'total' => -1, 'high' => -1 } }

      it { is_expected.to eq(expected_changes) }
    end

    context 'when the vulnerability is not destroyed' do
      context 'when the severity is changed' do
        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:severity, :critical) }
          let(:expected_changes) { { 'total' => 0, 'high' => -1, 'critical' => 1 } }

          it { is_expected.to eq(expected_changes) }
        end

        context 'when the state is changed' do
          shared_examples 'state & severity change together' do |from:, to:, expected_changes:|
            let(:update_vulnerability) { vulnerability.update!(state: to, severity: :critical) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(expected_changes) }
          end

          it_behaves_like 'state & severity change together', from: 'confirmed', to: 'detected', expected_changes: { 'total' => 0, 'high' => -1, 'critical' => 1 }
          it_behaves_like 'state & severity change together', from: 'confirmed', to: 'resolved', expected_changes: { 'total' => -1, 'high' => -1 }
          it_behaves_like 'state & severity change together', from: 'confirmed', to: 'dismissed', expected_changes: { 'total' => -1, 'high' => -1 }

          it_behaves_like 'state & severity change together', from: 'detected', to: 'confirmed', expected_changes: { 'total' => 0, 'high' => -1, 'critical' => 1 }
          it_behaves_like 'state & severity change together', from: 'detected', to: 'resolved', expected_changes: { 'total' => -1, 'high' => -1 }
          it_behaves_like 'state & severity change together', from: 'detected', to: 'dismissed', expected_changes: { 'total' => -1, 'high' => -1 }

          it_behaves_like 'state & severity change together', from: 'resolved', to: 'dismissed', expected_changes: { 'total' => 0 }
          it_behaves_like 'state & severity change together', from: 'resolved', to: 'confirmed', expected_changes: { 'total' => 1, 'critical' => 1 }
          it_behaves_like 'state & severity change together', from: 'resolved', to: 'detected', expected_changes: { 'total' => 1, 'critical' => 1 }

          it_behaves_like 'state & severity change together', from: 'dismissed', to: 'resolved', expected_changes: { 'total' => 0 }
          it_behaves_like 'state & severity change together', from: 'dismissed', to: 'confirmed', expected_changes: { 'total' => 1, 'critical' => 1 }
          it_behaves_like 'state & severity change together', from: 'dismissed', to: 'detected', expected_changes: { 'total' => 1, 'critical' => 1 }
        end
      end

      context 'when the severity is not changed' do
        context 'when the state is changed' do
          shared_examples 'state changes' do |from:, to:, expected_changes:|
            let(:update_vulnerability) { vulnerability.update_attribute(:state, to) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(expected_changes) }
          end

          it_behaves_like 'state changes', from: 'confirmed', to: 'detected', expected_changes: { 'total' => 0 }
          it_behaves_like 'state changes', from: 'confirmed', to: 'resolved', expected_changes: { 'total' => -1, 'high' => -1 }
          it_behaves_like 'state changes', from: 'confirmed', to: 'dismissed', expected_changes: { 'total' => -1, 'high' => -1 }

          it_behaves_like 'state changes', from: 'detected', to: 'confirmed', expected_changes: { 'total' => 0 }
          it_behaves_like 'state changes', from: 'detected', to: 'resolved', expected_changes: { 'total' => -1, 'high' => -1 }
          it_behaves_like 'state changes', from: 'detected', to: 'dismissed', expected_changes: { 'total' => -1, 'high' => -1 }

          it_behaves_like 'state changes', from: 'resolved', to: 'dismissed', expected_changes: { 'total' => 0 }
          it_behaves_like 'state changes', from: 'resolved', to: 'confirmed', expected_changes: { 'total' => 1, 'high' => 1 }
          it_behaves_like 'state changes', from: 'resolved', to: 'detected', expected_changes: { 'total' => 1, 'high' => 1 }

          it_behaves_like 'state changes', from: 'dismissed', to: 'resolved', expected_changes: { 'total' => 0 }
          it_behaves_like 'state changes', from: 'dismissed', to: 'confirmed', expected_changes: { 'total' => 1, 'high' => 1 }
          it_behaves_like 'state changes', from: 'dismissed', to: 'detected', expected_changes: { 'total' => 1, 'high' => 1 }
        end

        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:title, 'New Title') }
          let(:expected_changes) { { 'total' => 0 } }

          it { is_expected.to eq(expected_changes) }
        end
      end
    end
  end

  describe '#changed_attributes' do
    subject { stat_diff.changed_attributes }

    context 'when there are changes' do
      let(:expected_attribute_names) { %w(total high) }

      before do
        vulnerability.destroy!
      end

      it { is_expected.to eq(expected_attribute_names) }
    end

    context 'when there is no change' do
      let(:expected_attribute_names) { [] }

      before do
        vulnerability.reload
      end

      it { is_expected.to eq(expected_attribute_names) }
    end
  end

  describe '#change_values' do
    subject { stat_diff.change_values }

    context 'when there are changes' do
      let(:expected_values) { [-1, -1] }

      before do
        vulnerability.destroy!
      end

      it { is_expected.to eq(expected_values) }
    end

    context 'when there is no change' do
      let(:expected_values) { [] }

      before do
        vulnerability.reload
      end

      it { is_expected.to eq(expected_values) }
    end
  end
end

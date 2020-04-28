# frozen_string_literal: true
require 'spec_helper'

describe Ci::Minutes::Quota do
  let_it_be(:namespace) do
    create(:namespace, namespace_statistics: create(:namespace_statistics))
  end

  let(:quota) { described_class.new(namespace) }

  describe '#monthly_minutes_report' do
    context 'when unlimited' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit_enabled?).and_return(false)
      end

      context 'when minutes are not used' do
        it 'returns unlimited report with no usage' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 'Unlimited'
          expect(report.used).to eq 0
          expect(report.status).to eq :disabled
        end
      end

      context 'when minutes are used' do
        before do
          namespace.namespace_statistics.shared_runners_seconds = 20.minutes
        end

        it 'returns unlimited report with usage' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 'Unlimited'
          expect(report.used).to eq 20
          expect(report.status).to eq :disabled
        end
      end
    end

    context 'when limited' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 100
      end

      context 'when minutes are not all used' do
        before do
          namespace.namespace_statistics.shared_runners_seconds = 30.minutes
        end

        it 'returns report with under quota' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 100
          expect(report.used).to eq 30
          expect(report.status).to eq :under_quota
        end
      end

      context 'when minutes are all used' do
        before do
          namespace.namespace_statistics.shared_runners_seconds = 101.minutes
        end

        it 'returns report with over quota' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 100
          expect(report.used).to eq 101
          expect(report.status).to eq :over_quota
        end
      end
    end
  end

  describe '#purchased_minutes_report' do
    context 'when limit enabled' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 200
      end

      context 'when extra minutes have been purchased' do
        before do
          namespace.extra_shared_runners_minutes_limit = 100
        end

        context 'when all monthly minutes are used and some puarchased minutes are used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 250.minutes
          end

          it 'returns report with under quota' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 50
            expect(report.status).to eq :under_quota
          end
        end

        context 'when all monthly and all puarchased minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 301.minutes
          end

          it 'returns report with over quota' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 101
            expect(report.status).to eq :over_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 190.minutes
          end

          it 'returns report with no usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end
      end

      context 'when no extra minutes have been purchased' do
        before do
          namespace.extra_shared_runners_minutes_limit = nil
        end

        context 'when all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 201.minutes
          end

          it 'returns report without usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 190.minutes
          end

          it 'returns report with no usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end
      end
    end
  end
end

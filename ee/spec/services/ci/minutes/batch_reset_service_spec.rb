# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::BatchResetService do
  let(:service) { described_class.new }

  describe '#execute!' do
    def create_namespace_with_project(id, seconds_used)
      namespace = create(:namespace,
        id: id,
        shared_runners_minutes_limit: 100,
        extra_shared_runners_minutes_limit: 50,
        last_ci_minutes_notification_at: Time.current,
        last_ci_minutes_usage_notification_level: 30)

      create(:namespace_statistics, namespace: namespace, shared_runners_seconds: seconds_used)

      create(:project, namespace: namespace).tap do |project|
        create(:project_statistics,
          project: project,
          namespace: namespace,
          shared_runners_seconds: seconds_used)
      end

      namespace
    end

    subject { service.execute!(ids_range: ids_range, batch_size: 3) }

    let!(:namespace_1) { create_namespace_with_project(1, 120.minutes) }
    let!(:namespace_2) { create_namespace_with_project(2, 120.minutes) }
    let!(:namespace_3) { create_namespace_with_project(3, 120.minutes) }
    let!(:namespace_4) { create_namespace_with_project(4, 90.minutes) }
    let!(:namespace_5) { create_namespace_with_project(5, 90.minutes) }
    let!(:namespace_6) { create_namespace_with_project(6, 90.minutes) }

    context 'when ID range is provided' do
      let(:ids_range) { (1..5) }
      let(:namespaces_exceeding_minutes) { [namespace_1, namespace_2, namespace_3] }
      let(:namespaces_not_exceeding_minutes) { [namespace_4, namespace_5] }

      it 'resets minutes in batches for the given range' do
        expect(service).to receive(:reset_ci_minutes!).with([namespace_1, namespace_2, namespace_3])
        expect(service).to receive(:reset_ci_minutes!).with([namespace_4, namespace_5])

        subject
      end

      it 'resets CI minutes and recalculates purchased minutes for the namespace exceeding the monthly minutes' do
        subject

        namespaces_exceeding_minutes.each do |namespace|
          namespace.reset

          expect(namespace.extra_shared_runners_minutes_limit).to eq 30
          expect(namespace.namespace_statistics.shared_runners_seconds).to eq 0
          expect(namespace.namespace_statistics.shared_runners_seconds_last_reset).to be_present
          expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds).to eq 0
          expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds_last_reset).to be_present
          expect(namespace.last_ci_minutes_notification_at).to be_nil
          expect(namespace.last_ci_minutes_usage_notification_level).to be_nil
        end
      end

      it 'resets CI minutes but does not recalculate purchased minutes for the namespace not exceeding the monthly minutes' do
        subject

        namespaces_not_exceeding_minutes.each do |namespace|
          namespace.reset

          expect(namespace.extra_shared_runners_minutes_limit).to eq 50
          expect(namespace.namespace_statistics.shared_runners_seconds).to eq 0
          expect(namespace.namespace_statistics.shared_runners_seconds_last_reset).to be_present
          expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds).to eq 0
          expect(ProjectStatistics.find_by(namespace: namespace).shared_runners_seconds_last_reset).to be_present
          expect(namespace.last_ci_minutes_notification_at).to be_nil
          expect(namespace.last_ci_minutes_usage_notification_level).to be_nil
        end
      end
    end

    context 'when ID range is not provided' do
      let(:ids_range) { nil }

      it 'resets minutes in batches for all namespaces' do
        expect(service).to receive(:reset_ci_minutes!).with([namespace_1, namespace_2, namespace_3])
        expect(service).to receive(:reset_ci_minutes!).with([namespace_4, namespace_5, namespace_6])

        subject
      end
    end

    context 'when an ActiveRecordError is raised' do
      let(:ids_range) { nil }

      before do
        allow(Namespace).to receive(:transaction).and_raise(ActiveRecord::ActiveRecordError)
      end

      it 'decorates the error with more information' do
        expect { subject }
          .to raise_error(
            Ci::Minutes::BatchResetService::BatchNotResetError,
            '3 namespace shared runner minutes were not reset and the transaction was rolled back. Namespace Ids: [1, 2, 3]')
      end
    end
  end
end

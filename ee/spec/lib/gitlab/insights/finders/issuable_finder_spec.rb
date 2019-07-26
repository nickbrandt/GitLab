# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Finders::IssuableFinder do
  around do |example|
    Timecop.freeze(Time.utc(2019, 3, 5)) { example.run }
  end

  let(:base_opts) do
    {
      state: 'opened',
      group_by: 'months'
    }
  end

  describe '#find' do
    def find(entity, opts)
      described_class.new(entity, nil, opts).find
    end

    it 'raises an error for an invalid :issuable_type option' do
      expect { find(build(:project), issuable_type: 'foo') }.to raise_error(described_class::InvalidIssuableTypeError, "Invalid `:issuable_type` option: `foo`. Allowed values are #{described_class::FINDERS.keys}!")
    end

    it 'raises an error for an invalid entity object' do
      expect { find(build(:user), issuable_type: 'issue') }.to raise_error(described_class::InvalidEntityError, 'Entity class `User` is not supported. Supported classes are Project and Namespace!')
    end

    it 'raises an error for an invalid :group_by option' do
      expect { find(build(:project), issuable_type: 'issue', group_by: 'foo') }.to raise_error(described_class::InvalidGroupByError, "Invalid `:group_by` option: `foo`. Allowed values are #{described_class::PERIODS.keys}!")
    end

    it 'defaults to the "days" period if no :group_by is given' do
      expect(described_class.new(build(:project), nil, issuable_type: 'issue').__send__(:period)).to eq(:days)
    end

    it 'raises an error for an invalid :period_limit option' do
      expect { find(build(:project), issuable_type: 'issue', group_by: 'months', period_limit: 'many') }.to raise_error(described_class::InvalidPeriodLimitError, "Invalid `:period_limit` option: `many`. Expected an integer!")
    end

    shared_examples_for "insights issuable finder" do
      let(:label_bug) { create(label_type, label_entity_association_key => entity, name: 'Bug') }
      let(:label_manage) { create(label_type, label_entity_association_key => entity, name: 'Manage') }
      let(:label_plan) { create(label_type, label_entity_association_key => entity, name: 'Plan') }
      let(:label_create) { create(label_type, label_entity_association_key => entity, name: 'Create') }
      let(:label_quality) { create(label_type, label_entity_association_key => entity, name: 'Quality') }
      let(:extra_issuable_attrs) { [{}, {}, {}, {}, {}, {}] }
      let!(:issuable0) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2018, 2, 1), project_association_key => project, **extra_issuable_attrs[0]) }
      let!(:issuable1) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2018, 2, 1), labels: [label_bug, label_manage], project_association_key => project, **extra_issuable_attrs[1]) }
      let!(:issuable2) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 2, 6), labels: [label_bug, label_plan], project_association_key => project, **extra_issuable_attrs[2]) }
      let!(:issuable3) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 2, 20), labels: [label_bug, label_create], project_association_key => project, **extra_issuable_attrs[3]) }
      let!(:issuable4) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_quality], project_association_key => project, **extra_issuable_attrs[4]) }
      let(:opts) do
        base_opts.merge(
          issuable_type: issuable_type,
          filter_labels: [label_bug.title],
          collection_labels: [label_manage.title, label_plan.title, label_create.title])
      end

      subject { find(entity, opts) }

      it 'avoids N + 1 queries' do
        control_queries = ActiveRecord::QueryRecorder.new { subject.map { |issuable| issuable.labels.map(&:title) } }
        create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug], project_association_key => project, **extra_issuable_attrs[5])

        expect { find(entity, opts).map { |issuable| issuable.labels.map(&:title) } }.not_to exceed_query_limit(control_queries)
      end

      context ':period_limit option' do
        context 'with group_by: "day"' do
          before do
            opts.merge!(group_by: 'day')
          end

          it 'returns issuable created after 30 days ago' do
            expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "day", period_limit: 1' do
          before do
            opts.merge!(group_by: 'day', period_limit: 1)
          end

          it 'returns issuable created after one day ago' do
            expect(subject.to_a).to eq([issuable4])
          end
        end

        context 'with group_by: "week"' do
          before do
            opts.merge!(group_by: 'week')
          end

          it 'returns issuable created after 12 weeks ago' do
            expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "week", period_limit: 1' do
          before do
            opts.merge!(group_by: 'week', period_limit: 1)
          end

          it 'returns issuable created after one week ago' do
            expect(subject.to_a).to eq([issuable4])
          end
        end

        context 'with group_by: "month"' do
          before do
            opts.merge!(group_by: 'month')
          end

          it 'returns issuable created after 12 months ago' do
            expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "month", period_limit: 1' do
          before do
            opts.merge!(group_by: 'month', period_limit: 1)
          end

          it 'returns issuable created after one month ago' do
            expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
          end
        end
      end
    end

    shared_examples_for 'group tests' do
      let(:entity) { create(:group) }
      let(:label_type) { :group_label }
      let(:label_entity_association_key) { :group }

      context 'issues' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'issue' }
          let(:project_association_key) { :project }
        end
      end

      context 'merge requests' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'merge_request' }
          let(:project_association_key) { :source_project }
          let(:extra_issuable_attrs) do
            [
              { source_branch: "add_images_and_changes" },
              { source_branch: "improve/awesome" },
              { source_branch: "feature_conflict" },
              { source_branch: "markdown" },
              { source_branch: "feature_one" },
              { source_branch: "merged-target" }
            ]
          end
        end
      end
    end

    context 'for a group' do
      include_examples 'group tests' do
        let(:project) { create(:project, :public, group: entity) }
      end
    end

    context 'for a group with subgroups' do
      include_examples 'group tests' do
        let(:project) { create(:project, :public, group: create(:group, parent: entity)) }
      end
    end

    context 'for a project' do
      let(:project) { create(:project, :public) }
      let(:entity) { project }
      let(:label_type) { :label }
      let(:label_entity_association_key) { :project }

      context 'issues' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'issue' }
          let(:project_association_key) { :project }
        end
      end

      context 'merge requests' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'merge_request' }
          let(:project_association_key) { :source_project }
          let(:extra_issuable_attrs) do
            [
              { source_branch: "add_images_and_changes" },
              { source_branch: "improve/awesome" },
              { source_branch: "feature_conflict" },
              { source_branch: "markdown" },
              { source_branch: "feature_one" },
              { source_branch: "merged-target" }
            ]
          end
        end
      end
    end
  end

  describe '#period_limit' do
    subject { described_class.new(create(:project, :public), nil, opts).period_limit }

    describe 'default values' do
      context 'with group_by: "day"' do
        let(:opts) { base_opts.merge!(group_by: 'day') }

        it 'returns 30' do
          expect(subject).to eq(30)
        end
      end

      context 'with group_by: "week"' do
        let(:opts) { base_opts.merge!(group_by: 'week') }

        it 'returns 12' do
          expect(subject).to eq(12)
        end
      end

      context 'with group_by: "month"' do
        let(:opts) { base_opts.merge!(group_by: 'month') }

        it 'returns 12' do
          expect(subject).to eq(12)
        end
      end
    end

    describe 'custom values' do
      context 'with period_limit: 42' do
        let(:opts) { base_opts.merge!(period_limit: 42) }

        it 'returns 42' do
          expect(subject).to eq(42)
        end
      end

      context 'with an invalid period_limit' do
        let(:opts) { base_opts.merge!(period_limit: 'many') }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::InvalidPeriodLimitError, "Invalid `:period_limit` option: `many`. Expected an integer!")
        end
      end
    end
  end
end

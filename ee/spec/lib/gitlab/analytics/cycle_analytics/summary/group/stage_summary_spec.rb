# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Analytics::CycleAnalytics::Summary::Group::StageSummary do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:project_2) { create(:project, :repository, namespace: group) }
  let(:created_after) { 10.days.ago }
  let(:user) { create(:user, :admin) }

  let(:options) do
    Gitlab::Analytics::CycleAnalytics::RequestParams.new(
      created_after: created_after,
      current_user: user,
      group: group
    ).to_data_collector_params
  end

  subject { described_class.new(group, options: options).data }

  describe "#new_issues" do
    context 'with created_after date' do
      before do
        Timecop.freeze(5.days.ago) { create(:issue, project: project) }
        Timecop.freeze(5.days.ago) { create(:issue, project: project_2) }
        Timecop.freeze(5.days.from_now) { create(:issue, project: project) }
        Timecop.freeze(5.days.from_now) { create(:issue, project: project_2) }
      end

      it "finds the number of issues created after it" do
        expect(subject.first[:value]).to eq('2')
      end

      context 'with subgroups' do
        before do
          Timecop.freeze(4.days.ago) { create(:issue, project: create(:project, namespace: create(:group, parent: group))) }
        end

        it "finds issues created_after them" do
          expect(subject.first[:value]).to eq('3')
        end
      end

      context 'with projects specified in options' do
        before do
          Timecop.freeze(4.days.ago) { create(:issue, project: create(:project, namespace: group)) }

          options[:projects] = [project.id, project_2.id]
        end

        it 'finds issues from those projects' do
          expect(subject.first[:value]).to eq('2')
        end
      end

      context 'when `created_after` and `created_before` parameters are provided' do
        before do
          options[:created_after] = 10.days.ago
          options[:created_before] = Time.now
        end

        it 'finds issues from 5 days ago' do
          expect(subject.first[:value]).to eq('2')
        end
      end
    end

    context 'with other projects' do
      before do
        Timecop.freeze(4.days.ago) { create(:issue, project: create(:project, namespace: create(:group))) }
        Timecop.freeze(4.days.ago) { create(:issue, project: project) }
        Timecop.freeze(4.days.ago) { create(:issue, project: project_2) }
      end

      it "doesn't find issues from them" do
        expect(subject.first[:value]).to eq('2')
      end
    end
  end

  describe "#deploys" do
    context 'with created_after date' do
      before do
        Timecop.freeze(5.days.ago) { create(:deployment, :success, project: project) }
        Timecop.freeze(5.days.from_now) { create(:deployment, :success, project: project) }
        Timecop.freeze(5.days.ago) { create(:deployment, :success, project: project_2) }
        Timecop.freeze(5.days.from_now) { create(:deployment, :success, project: project_2) }
      end

      it "finds the number of deploys made created after it" do
        expect(subject.second[:value]).to eq('2')
      end

      context 'with subgroups' do
        before do
          Timecop.freeze(4.days.ago) do
            create(:deployment, :success, project: create(:project, :repository, namespace: create(:group, parent: group)))
          end
        end

        it "finds deploys from them" do
          expect(subject.second[:value]).to eq('3')
        end
      end

      context 'with projects specified in options' do
        before do
          Timecop.freeze(4.days.ago) do
            create(:deployment, :success, project: create(:project, :repository, namespace: group, name: 'not_applicable'))
          end

          options[:projects] = [project.id, project_2.id]
        end

        it 'shows deploys from those projects' do
          expect(subject.second[:value]).to eq('2')
        end
      end

      context 'when `created_after` and `created_before` parameters are provided' do
        before do
          options[:created_after] = 10.days.ago
          options[:created_before] = Time.now
        end

        it 'finds deployments from 5 days ago' do
          expect(subject.second[:value]).to eq('2')
        end
      end
    end

    context 'with other projects' do
      before do
        Timecop.freeze(5.days.from_now) do
          create(:deployment, :success, project: create(:project, :repository, namespace: create(:group)))
        end
      end

      it "doesn't find deploys from them" do
        expect(subject.second[:value]).to eq('-')
      end
    end
  end

  describe '#deployment_frequency' do
    let(:created_after) { 6.days.ago }

    subject { described_class.new(group, options: options).data.third }

    before do
      Timecop.freeze(5.days.ago) do
        create(:deployment, :success, project: project)
      end

      options[:created_after] = created_after
    end

    it 'includes the unit: `per day`' do
      expect(subject[:unit]).to eq(_('per day'))
    end

    context 'when `created_before` is nil' do
      it 'includes range until now' do
        # 1 deployment over 7 days
        expect(subject[:value]).to eq('0.1')
      end
    end

    context 'when `created_before` is given' do
      let(:created_after) { 10.days.ago }
      let(:created_before) { 10.days.from_now }

      before do
        Timecop.freeze(5.days.from_now) do
          create(:deployment, :success, project: project)
        end
      end

      it 'returns deployment frequency within `created_after` and `created_before` range' do
        # 2 deployments over 20 days
        expect(subject[:value]).to eq('0.1')
      end
    end
  end
end

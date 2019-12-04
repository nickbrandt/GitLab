# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cluster do
  it { is_expected.to include_module(HasEnvironmentScope) }

  describe 'validation' do
    subject { cluster.valid? }

    context 'when validates unique_environment_scope' do
      context 'for a project cluster' do
        let(:project) { create(:project) }

        before do
          create(:cluster, projects: [project], environment_scope: 'product/*')
        end

        context 'when identical environment scope exists in project' do
          let(:cluster) { build(:cluster, projects: [project], environment_scope: 'product/*') }

          it { is_expected.to be_falsey }
        end

        context 'when identical environment scope does not exist in project' do
          let(:cluster) { build(:cluster, projects: [project], environment_scope: '*') }

          it { is_expected.to be_truthy }
        end

        context 'when identical environment scope exists in different project' do
          let(:project2) { create(:project) }
          let(:cluster) { build(:cluster, projects: [project2], environment_scope: 'product/*') }

          it { is_expected.to be_truthy }
        end
      end

      context 'for a group cluster' do
        let(:group) { create(:group) }

        before do
          create(:cluster, cluster_type: :group_type, groups: [group], environment_scope: 'product/*')
        end

        context 'when identical environment scope exists in group' do
          let(:cluster) { build(:cluster, cluster_type: :group_type, groups: [group], environment_scope: 'product/*') }

          it { is_expected.to be_falsey }
        end

        context 'when identical environment scope does not exist in group' do
          let(:cluster) { build(:cluster, cluster_type: :group_type, groups: [group], environment_scope: '*') }

          it { is_expected.to be_truthy }
        end

        context 'when identical environment scope exists in different group' do
          let(:cluster) { build(:cluster, :group, environment_scope: 'product/*') }

          it { is_expected.to be_truthy }
        end
      end

      context 'for an instance cluster' do
        before do
          create(:cluster, :instance, environment_scope: 'product/*')
        end

        context 'identical environment scope exists' do
          let(:cluster) { build(:cluster, :instance, environment_scope: 'product/*') }

          it { is_expected.to be_falsey }
        end

        context 'identical environment scope does not exist' do
          let(:cluster) { build(:cluster, :instance, environment_scope: '*') }

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end

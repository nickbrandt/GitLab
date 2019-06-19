# frozen_string_literal: true

require 'spec_helper'

describe Clusters::InstancePolicy do
  let(:user) { create(:admin) }
  let(:policy) { described_class.new(user, Clusters::Instance.new) }

  describe 'rules' do
    context 'multiple clusters allowed' do
      before do
        stub_feature_flags(multiple_clusters: true)
      end

      context 'no existing instance level cluster' do
        it { expect(policy).to be_allowed :add_cluster }
      end

      context 'with an existing instance level cluster' do
        before do
          create(:cluster, :instance)
        end

        it { expect(policy).to be_allowed :add_cluster }
      end
    end

    context 'multiple clusters disallowed' do
      before do
        stub_feature_flags(multiple_clusters: false)
      end

      context 'no existing instance level cluster' do
        it { expect(policy).to be_allowed :add_cluster }
      end

      context 'with an existing instance level cluster' do
        before do
          create(:cluster, :instance)
        end

        it { expect(policy).to be_disallowed :add_cluster }
      end
    end
  end
end

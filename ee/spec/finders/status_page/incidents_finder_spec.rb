# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::IncidentsFinder do
  let_it_be(:project) { create(:project) }

  let_it_be(:issues) do
    {
      public: create_list(:issue, 2, project: project),
      confidential: create(:issue, :confidential, project: project),
      unrelated: create(:issue)
    }
  end

  let(:public_issues) { issues.fetch(:public) }
  let(:finder) { described_class.new(project_id: project.id) }

  describe '#find_by_id' do
    subject { finder.find_by_id(issue.id) }

    context 'for public issue' do
      let(:issue) { public_issues.first }

      it { is_expected.to eq(issue) }
    end

    context 'for confidential issue' do
      let(:issue) { issues.fetch(:confidential) }

      it { is_expected.to be_nil }
    end

    context 'for unrelated issue' do
      let(:issue) { issues.fetch(:unrelated) }

      it { is_expected.to be_nil }
    end
  end

  describe '#all' do
    let(:sorted_issues) { public_issues.sort_by(&:created_at).reverse }

    subject { finder.all }

    before do
      stub_const("#{described_class}::MAX_LIMIT", limit)
    end

    context 'when limit is higher than the colletion size' do
      let(:limit) { public_issues.size + 1 }

      it { is_expected.to eq(sorted_issues) }
    end

    context 'when limit is lower than the colletion size' do
      let(:limit) { public_issues.size - 1 }

      it { is_expected.to eq(sorted_issues.first(1)) }
    end
  end
end

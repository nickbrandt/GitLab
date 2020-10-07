# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableSla do
  describe 'associations' do
    it { is_expected.to belong_to(:issue).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:due_at) }
  end

  describe 'scopes' do
    describe '.exceeded_for_issues' do
      subject { described_class.exceeded_for_issues }

      let_it_be(:project) { create(:project) }
      let!(:issuable_sla) { create(:issuable_sla, issue: issue, due_at: due_at) }
      let(:due_at) { Time.current - 1.hour }
      let(:issue) { create(:issue, project: project) }

      context 'issue closed' do
        let(:issue) { create(:issue, :closed, project: project) }

        it { is_expected.to be_empty }
      end

      context 'issue opened' do
        context 'due_at has not passed' do
          let(:due_at) { Time.current + 1.hour }

          it { is_expected.to be_empty }
        end

        it { is_expected.to contain_exactly(issuable_sla) }
      end
    end
  end
end

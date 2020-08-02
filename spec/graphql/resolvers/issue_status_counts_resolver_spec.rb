# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IssueStatusCountsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let(:args) { {} }

    subject { resolve_issue_status_counts(args) }

    it { is_expected.to be_a(Gitlab::IssuablesCountForState) }
    specify { expect(subject.project).to eq(project) }

    private

    def resolve_issue_status_counts(args = {}, context = { current_user: current_user })
      resolve(described_class, obj: project, args: args, ctx: context)
    end
  end
end

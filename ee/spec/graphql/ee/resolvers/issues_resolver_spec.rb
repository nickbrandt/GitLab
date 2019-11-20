# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::IssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:project) { create(:project) }

  context "with a project" do
    describe '#resolve' do
      describe 'sorting' do
        context 'when sorting by weight' do
          let!(:weight_issue1) { create(:issue, project: project, weight: 5) }
          let!(:weight_issue2) { create(:issue, project: project, weight: nil) }
          let!(:weight_issue3) { create(:issue, project: project, weight: 1) }
          let!(:weight_issue4) { create(:issue, project: project, weight: nil) }

          before do
            project.add_developer(current_user)
          end

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :weight_asc)).to eq [weight_issue3, weight_issue1, weight_issue4, weight_issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :weight_desc)).to eq [weight_issue1, weight_issue3, weight_issue4, weight_issue2]
          end
        end
      end
    end
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end

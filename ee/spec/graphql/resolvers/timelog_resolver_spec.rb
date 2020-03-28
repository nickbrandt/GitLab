# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::TimelogResolver do
  include GraphqlHelpers

  context "within a group" do
    let(:current_user) { create(:user) }
    let(:user)         { create(:user) }
    let(:group)        { create(:group) }
    let(:project)      { create(:project, :public, group: group) }

    before do
      group.add_users([current_user, user], :developer)
      project.add_developer(user)
      stub_licensed_features(group_timelogs: true)
    end

    describe '#resolve' do
      let(:issue)       { create(:issue, project: project) }
      let(:issue2)      { create(:issue, project: project) }
      let!(:timelog1)   { create(:timelog, issue: issue, user: user, spent_at: 5.days.ago) }
      let!(:timelog2)   { create(:timelog, issue: issue2, user: user, spent_at: 10.days.ago) }
      let(:start_date)  { 6.days.ago }
      let(:end_date)    { 2.days.ago }

      shared_examples 'validation fails with error' do
        it 'raises error with correct message' do
          expect { resolve_timelogs(start_date: start_date, end_date: end_date) }
            .to raise_error(
              error_type,
              message
            )
        end
      end

      it 'finds all timelogs within given dates' do
        timelogs = resolve_timelogs(start_date: start_date, end_date: end_date)

        expect(timelogs).to contain_exactly(timelog1)
      end

      context 'when arguments are invalid' do
        let(:error_type) { Gitlab::Graphql::Errors::ArgumentError }

        context 'when only start_date is present' do
          let(:end_date) { nil }
          let(:message) { 'Both start_date and end_date must be present.' }

          it_behaves_like 'validation fails with error'
        end

        context 'when only end_date is present' do
          let(:start_date) { nil }
          let(:message) { 'Both start_date and end_date must be present.' }

          it_behaves_like 'validation fails with error'
        end

        context 'when start_date is later than end_date' do
          let(:start_date) { 3.days.ago }
          let(:end_date) { 5.days.ago }
          let(:message) { 'start_date must be earlier than end_date.' }

          it_behaves_like 'validation fails with error'
        end

        context 'when time range is more than 60 days' do
          let(:start_date) { 3.months.ago }
          let(:end_date) { 1.day.ago }
          let(:message) { 'The date range period cannot contain more than 60 days' }

          it_behaves_like 'validation fails with error'
        end
      end

      context 'when resource is not available' do
        let(:error_type) { Gitlab::Graphql::Errors::ResourceNotAvailable }
        let(:message) { "The resource is not available or you don't have permission to perform this action" }

        context 'when feature is disabled' do
          before do
            stub_licensed_features(group_timelogs: false)
          end

          it_behaves_like 'validation fails with error'
        end

        context "when user has insufficient permissions" do
          before do
            group.add_guest(current_user)
          end

          it_behaves_like 'validation fails with error'
        end
      end
    end
  end

  def resolve_timelogs(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: group, args: args, ctx: context)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::VulnerabilitiesHistoryResolver do
  include GraphqlHelpers

  subject(:ordered_history) { resolve(described_class, obj: group, args: args, ctx: { current_user: user }) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    let(:args) { { start_date: Date.parse('2019-10-15'), end_date: Date.parse('2019-10-21') } }

    it "fetches historical vulnerability data from the start date to the end date" do
      Timecop.freeze(Date.parse('2019-10-31')) do
        create(:vulnerability_historical_statistic, date: 15.days.ago, critical: 1, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 14.days.ago, critical: 2, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 13.days.ago, critical: 2, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 12.days.ago, critical: 1, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 11.days.ago, critical: 1, high: 0, project: project)
        create(:vulnerability_historical_statistic, date: 10.days.ago, critical: 0, high: 0, project: project)

        expected_history = [
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 1, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 1, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-16', 'count' => 0, 'severity' => 'unknown' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 2, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 1, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-17', 'count' => 0, 'severity' => 'unknown' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 2, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 1, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-18', 'count' => 0, 'severity' => 'unknown' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 1, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 1, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-19', 'count' => 0, 'severity' => 'unknown' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 1, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 0, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-20', 'count' => 0, 'severity' => 'unknown' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'critical' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'high' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'info' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'low' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'medium' },
          { 'id' => nil, 'day' => '2019-10-21', 'count' => 0, 'severity' => 'unknown' }
        ]


        expect(ordered_history.as_json).to match_array(expected_history)
      end
    end
  end
end

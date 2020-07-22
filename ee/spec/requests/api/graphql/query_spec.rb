# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query' do
  include GraphqlHelpers

  describe '.vulnerabilitiesCountByDayAndSeverity' do
    let(:query_result) { graphql_data.dig('vulnerabilitiesCountByDayAndSeverity', 'nodes') }

    let(:query) do
      graphql_query_for(
        :vulnerabilitiesCountByDayAndSeverity,
        {
          start_date: Date.parse('2019-10-15').iso8601,
          end_date: Date.parse('2019-10-21').iso8601
        },
        history_fields
      )
    end

    let(:history_fields) do
      query_graphql_field(:nodes, nil, <<~FIELDS)
        count
        day
        severity
      FIELDS
    end

    it "fetches historical vulnerability data from the start date to the end date for projects on the current user's instance security dashboard" do
      Timecop.freeze(Time.zone.parse('2019-10-31')) do
        project = create(:project)
        current_user = create(:user)
        current_user.security_dashboard_projects << project
        project.add_developer(current_user)

        create(:vulnerability_historical_statistic, date: 15.days.ago, critical: 1, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 14.days.ago, critical: 2, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 13.days.ago, critical: 2, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 12.days.ago, critical: 1, high: 1, project: project)
        create(:vulnerability_historical_statistic, date: 11.days.ago, critical: 1, high: 0, project: project)
        create(:vulnerability_historical_statistic, date: 10.days.ago, critical: 0, high: 0, project: project)

        post_graphql(query, current_user: current_user)

        expected_history = [
          { 'day' => '2019-10-16', 'count' => 1, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-16', 'count' => 1, 'severity' => 'HIGH' },
          { 'day' => '2019-10-16', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-16', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-16', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-16', 'count' => 0, 'severity' => 'UNKNOWN' },
          { 'day' => '2019-10-17', 'count' => 2, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-17', 'count' => 1, 'severity' => 'HIGH' },
          { 'day' => '2019-10-17', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-17', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-17', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-17', 'count' => 0, 'severity' => 'UNKNOWN' },
          { 'day' => '2019-10-18', 'count' => 2, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-18', 'count' => 1, 'severity' => 'HIGH' },
          { 'day' => '2019-10-18', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-18', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-18', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-18', 'count' => 0, 'severity' => 'UNKNOWN' },
          { 'day' => '2019-10-19', 'count' => 1, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-19', 'count' => 1, 'severity' => 'HIGH' },
          { 'day' => '2019-10-19', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-19', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-19', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-19', 'count' => 0, 'severity' => 'UNKNOWN' },
          { 'day' => '2019-10-20', 'count' => 1, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-20', 'count' => 0, 'severity' => 'HIGH' },
          { 'day' => '2019-10-20', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-20', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-20', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-20', 'count' => 0, 'severity' => 'UNKNOWN' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'CRITICAL' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'HIGH' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'INFO' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'LOW' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'MEDIUM' },
          { 'day' => '2019-10-21', 'count' => 0, 'severity' => 'UNKNOWN' }
        ]

        expect(query_result).to eq(expected_history)
      end
    end
  end
end

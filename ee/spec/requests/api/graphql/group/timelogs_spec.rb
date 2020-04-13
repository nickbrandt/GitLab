# frozen_string_literal: true

require 'spec_helper'

describe 'Timelogs through GroupQuery' do
  include GraphqlHelpers

  describe 'Get list of timelogs from a group issues' do
    let(:user)          { create(:user) }
    let(:group)         { create(:group) }
    let(:project)       { create(:project, :public, group: group) }
    let(:milestone)     { create(:milestone, group: group) }
    let(:epic)          { create(:epic, group: group) }
    let(:issue)         { create(:issue, project: project, milestone: milestone, epic: epic) }
    let!(:timelog1)     { create(:timelog, issue: issue, user: user, spent_at: 10.days.ago) }
    let!(:timelog2)     { create(:timelog, spent_at: 15.days.ago) }
    let(:timelogs_data) { graphql_data['group']['timelogs']['nodes'] }
    let(:query) do
      timelog_nodes = <<~NODE
      nodes {
        date
        spentAt
        timeSpent
        user {
          username
        }
        issue {
          title
          milestone {
            title
          }
          epic {
            title
          }
        }
      }
      NODE

      graphql_query_for("group", { "fullPath" => group.full_path },
        ['groupTimelogsEnabled', query_graphql_field(
          "timelogs",
          { startDate: "#{13.days.ago.to_date}", endDate: "#{2.days.ago.to_date}" },
          timelog_nodes
        )]
      )
    end

    before do
      group.add_developer(user)
      stub_licensed_features(group_timelogs: true, epics: true)
    end

    context 'when the request is correct' do
      before do
        post_graphql(query, current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns timelogs successfully' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to be_nil
        expect(timelog_array.size).to eq 1
        expect(graphql_data['group']['groupTimelogsEnabled']).to be_truthy
      end

      it 'contains correct data' do
        username = timelog_array.map {|data| data['user']['username'] }
        date = timelog_array.map { |data| data['date'].to_time }
        spent_at = timelog_array.map { |data| data['spentAt'].to_time }
        time_spent = timelog_array.map { |data| data['timeSpent'] }
        issue_title = timelog_array.map {|data| data['issue']['title'] }
        milestone_title = timelog_array.map {|data| data['issue']['milestone']['title'] }
        epic_title = timelog_array.map {|data| data['issue']['epic']['title'] }

        expect(username).to eq([user.username])
        expect(date.first).to be_like_time(timelog1.spent_at)
        expect(spent_at.first).to be_like_time(timelog1.spent_at)
        expect(time_spent).to eq([timelog1.time_spent])
        expect(issue_title).to eq([issue.title])
        expect(milestone_title).to eq([milestone.title])
        expect(epic_title).to eq([epic.title])
      end
    end

    context 'when requests has errors' do
      let(:error_message) do
        "The resource is not available or you don't have permission to perform this action"
      end

      context 'when group_timelogs feature is disabled' do
        before do
          stub_licensed_features(group_timelogs: false)
        end

        it 'returns empty' do
          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to include(a_hash_including('message' => error_message))
          expect(graphql_data['group']).to be_nil
        end
      end

      context 'when there are no timelogs present' do
        before do
          Timelog.delete_all
        end

        it 'returns empty result' do
          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(timelogs_data).to be_empty
          expect(graphql_data['group']['groupTimelogsEnabled']).to be_truthy
        end
      end

      context 'when user has no permission to read group timelogs' do
        it 'returns empty result' do
          guest = create(:user)
          group.add_guest(guest)
          post_graphql(query, current_user: guest)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to include(a_hash_including('message' => error_message))
          expect(graphql_data['group']).to be_nil
        end
      end
    end
  end

  def timelog_array(extract_attribute = nil)
    timelogs_data.map do |item|
      extract_attribute ? item[extract_attribute] : item
    end
  end
end

require 'spec_helper'

describe EpicsHelper do
  include ApplicationHelper

  describe '#epic_show_app_data' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:milestone1) { create(:milestone, title: 'make me a sandwich', start_date: '2010-01-01', due_date: '2019-12-31') }
    let(:milestone2) { create(:milestone, title: 'make me a pizza', start_date: '2020-01-01', due_date: '2029-12-31') }
    let(:parent_epic) { create(:epic, group: group, start_date: Date.new(2000, 1, 10), due_date: Date.new(2000, 1, 20)) }
    let!(:epic) do
      create(
        :epic,
        group: group,
        author: user,
        start_date_sourcing_milestone: milestone1,
        start_date: Date.new(2000, 1, 1),
        due_date_sourcing_milestone: milestone2,
        due_date: Date.new(2000, 1, 2),
        parent: parent_epic
      )
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
      stub_licensed_features(epics: true)
    end

    it 'returns the correct json' do
      data = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
      meta_data = JSON.parse(data[:meta])

      expected_keys = %i(initial meta namespace labels_path toggle_subscription_path labels_web_url epics_web_url)
      expect(data.keys).to match_array(expected_keys)
      expect(meta_data.keys).to match_array(%w[
        epic_id created author todo_exists todo_path start_date ancestors
        start_date_is_fixed start_date_fixed start_date_from_milestones
        start_date_sourcing_milestone_title start_date_sourcing_milestone_dates
        due_date due_date_is_fixed due_date_fixed due_date_from_milestones due_date_sourcing_milestone_title
        due_date_sourcing_milestone_dates end_date state namespace labels_path toggle_subscription_path
        labels_web_url epics_web_url lock_version
      ])
      expect(meta_data['author']).to eq({
        'name' => user.name,
        'url' => "/#{user.username}",
        'username' => "@#{user.username}",
        'src' => 'icon_path'
      })
      expect(meta_data['start_date']).to eq('2000-01-01')
      expect(meta_data['start_date_sourcing_milestone_title']).to eq(milestone1.title)
      expect(meta_data['start_date_sourcing_milestone_dates']['start_date']).to eq(milestone1.start_date.to_s)
      expect(meta_data['start_date_sourcing_milestone_dates']['due_date']).to eq(milestone1.due_date.to_s)
      expect(meta_data['due_date']).to eq('2000-01-02')
      expect(meta_data['due_date_sourcing_milestone_title']).to eq(milestone2.title)
      expect(meta_data['due_date_sourcing_milestone_dates']['start_date']).to eq(milestone2.start_date.to_s)
      expect(meta_data['due_date_sourcing_milestone_dates']['due_date']).to eq(milestone2.due_date.to_s)
    end

    it 'returns a list of epic ancestors', :nested_groups do
      data = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
      meta_data = JSON.parse(data[:meta])

      expect(meta_data['ancestors']).to eq([{
        'id' => parent_epic.id,
        'title' => parent_epic.title,
        'url' => "/groups/#{group.full_path}/-/epics/#{parent_epic.iid}",
        'state' => 'opened',
        'human_readable_end_date' => 'Jan 20, 2000',
        'human_readable_timestamp' => '<strong>Past due</strong>'
      }])
    end

    it 'avoids N+1 database queries', :nested_groups do
      group1 = create(:group)
      group2 = create(:group, parent: group1)
      epic1 = create(:epic, group: group1)
      epic2 = create(:epic, group: group1, parent: epic1)
      epic3 = create(:epic, group: group2, parent: epic2)

      control_count = ActiveRecord::QueryRecorder.new { helper.epic_show_app_data(epic2, initial: {}) }

      expect { helper.epic_show_app_data(epic3, initial: {}) }.not_to exceed_query_limit(control_count)
    end

    context 'when a user can update an epic' do
      let(:milestone) { create(:milestone, title: 'make me a sandwich') }

      let!(:epic) do
        create(
          :epic,
          author: user,
          start_date_sourcing_milestone: milestone1,
          start_date: Date.new(2000, 1, 1),
          due_date_sourcing_milestone: milestone2,
          due_date: Date.new(2000, 1, 2)
        )
      end

      before do
        epic.group.add_developer(user)
      end

      it 'returns extra date fields' do
        data = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
        meta_data = JSON.parse(data[:meta])

        expect(meta_data.keys).to match_array(%w[
          epic_id created author todo_exists todo_path start_date ancestors
          start_date_is_fixed start_date_fixed start_date_from_milestones
          start_date_sourcing_milestone_title start_date_sourcing_milestone_dates
          due_date due_date_is_fixed due_date_fixed due_date_from_milestones due_date_sourcing_milestone_title
          due_date_sourcing_milestone_dates end_date state namespace labels_path toggle_subscription_path
          labels_web_url epics_web_url lock_version
        ])
        expect(meta_data['start_date']).to eq('2000-01-01')
        expect(meta_data['start_date_sourcing_milestone_title']).to eq(milestone1.title)
        expect(meta_data['start_date_sourcing_milestone_dates']['start_date']).to eq(milestone1.start_date.to_s)
        expect(meta_data['start_date_sourcing_milestone_dates']['due_date']).to eq(milestone1.due_date.to_s)
        expect(meta_data['due_date']).to eq('2000-01-02')
        expect(meta_data['due_date_sourcing_milestone_title']).to eq(milestone2.title)
        expect(meta_data['due_date_sourcing_milestone_dates']['start_date']).to eq(milestone2.start_date.to_s)
        expect(meta_data['due_date_sourcing_milestone_dates']['due_date']).to eq(milestone2.due_date.to_s)
      end
    end
  end

  describe '#epic_endpoint_query_params' do
    it 'it includes epic specific options in JSON format' do
      opts = epic_endpoint_query_params({})

      expected = "{\"only_group_labels\":true,\"include_ancestor_groups\":true,\"include_descendant_groups\":true}"
      expect(opts[:data][:endpoint_query_params]).to eq(expected)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe EpicPresenter do
  include UsersHelper

  describe '#show_data' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:milestone1) { create(:milestone, title: 'make me a sandwich', start_date: '2010-01-01', due_date: '2019-12-31') }
    let(:milestone2) { create(:milestone, title: 'make me a pizza', start_date: '2020-01-01', due_date: '2029-12-31') }
    let(:parent_epic) { create(:epic, group: group, start_date: Date.new(2000, 1, 10), due_date: Date.new(2000, 1, 20)) }

    let(:epic) do
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

    let(:presenter) { described_class.new(epic, current_user: user) }

    before do
      stub_licensed_features(epics: true)
    end

    it 'has correct keys' do
      expect(presenter.show_data.keys).to match_array([:initial, :meta])
    end

    it 'returns the correct json schema for epic initial data' do
      data = presenter.show_data(author_icon: 'icon_path')

      expect(data[:initial]).to match_schema('epic_initial_data', dir: 'ee')
    end

    it 'returns the correct json schema for epic meta data' do
      data = presenter.show_data(author_icon: 'icon_path')

      expect(data[:meta]).to match_schema('epic_meta_data', dir: 'ee')
    end

    it 'avoids N+1 database queries', :nested_groups do
      group1 = create(:group)
      group2 = create(:group, parent: group1)
      epic1 = create(:epic, group: group1)
      epic2 = create(:epic, group: group1, parent: epic1)
      create(:epic, group: group2, parent: epic2)

      control_count = ActiveRecord::QueryRecorder.new { presenter.show_data }

      expect { presenter.show_data }.not_to exceed_query_limit(control_count)
    end
  end
end

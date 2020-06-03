# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicsHelper, type: :helper do
  include ApplicationHelper

  describe '#epic_endpoint_query_params' do
    let(:endpoint_data) do
      {
        only_group_labels: true,
        include_ancestor_groups: true,
        include_descendant_groups: true
      }
    end

    it 'includes Epic specific options in JSON format' do
      opts = epic_endpoint_query_params({})

      expect(opts[:data][:endpoint_query_params]).to eq(endpoint_data.to_json)
    end

    it 'includes data provided in param' do
      opts = epic_endpoint_query_params(data: { default_param: true })

      expect(opts[:data]).to eq({ default_param: true }.merge(endpoint_query_params: endpoint_data.to_json))
    end
  end

  describe '#epic_state_dropdown_link' do
    it 'returns the active link when selected state is same as the link' do
      expect(helper.epic_state_dropdown_link(:opened, :opened))
        .to eq('<a class="is-active" href="?state=opened">Open epics</a>')
    end

    it 'returns the non-active link when selected state is different from the link' do
      expect(helper.epic_state_dropdown_link(:opened, :closed))
        .to eq('<a class="" href="?state=opened">Open epics</a>')
    end
  end

  describe '#epic_state_title' do
    it 'returns "Open" when the state is opened' do
      expect(epic_state_title(:opened)).to eq('Open epics')
    end

    it 'returns humanized string when the state is other than opened' do
      expect(epic_state_title(:some_other_state)).to eq('Some other state epics')
    end
  end

  describe '#epic_timeframe' do
    let(:epic) { build(:epic, start_date: start_date, end_date: end_date) }

    subject { epic_timeframe(epic) }

    context 'when both dates are from the same year' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { Date.new(2018, 8, 15) }

      it 'returns start date with year omitted and end date with year' do
        is_expected.to eq('Jul 22 – Aug 15, 2018')
      end
    end

    context 'when both dates are from different years' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { Date.new(2019, 7, 22) }

      it 'returns start date with year omitted and end date with year' do
        is_expected.to eq('Jul 22, 2018 – Jul 22, 2019')
      end
    end

    context 'when only start date is present' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { nil }

      it 'returns start date with year' do
        is_expected.to eq('Jul 22, 2018 – No end date')
      end
    end

    context 'when only end date is present' do
      let(:start_date) { nil }
      let(:end_date) { Date.new(2018, 7, 22) }

      it 'returns end date with year' do
        is_expected.to eq('No start date – Jul 22, 2018')
      end
    end
  end
end

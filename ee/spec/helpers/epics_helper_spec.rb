# frozen_string_literal: true

require 'spec_helper'

describe EpicsHelper, type: :helper do
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
end

# frozen_string_literal: true

require 'spec_helper'

describe OperationsHelper do
  include Gitlab::Routing.url_helpers

  describe '#operations_data' do
    it 'returns frontend configuration' do
      expect(operations_data).to eq(
        'add-path' => '/-/operations',
        'list-path' => '/-/operations/list',
        'empty-dashboard-svg-path' => '/images/illustrations/operations-dashboard_empty.svg'
      )
    end
  end
end

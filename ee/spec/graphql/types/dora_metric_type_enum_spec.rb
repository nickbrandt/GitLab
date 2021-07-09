# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::DoraMetricTypeEnum do
  it 'includes a value for each DORA metric type' do
    expect(described_class.values).to match(
      'DEPLOYMENT_FREQUENCY' => have_attributes(value: 'deployment_frequency'),
      'LEAD_TIME_FOR_CHANGES' => have_attributes(value: 'lead_time_for_changes')
    )
  end
end

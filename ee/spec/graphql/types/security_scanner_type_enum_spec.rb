# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityScannerType'] do
  it 'exposes all security scanner types' do
    expect(described_class.values.keys).to match_array(%w[API_FUZZING CLUSTER_IMAGE_SCANNING CONTAINER_SCANNING COVERAGE_FUZZING DAST DEPENDENCY_SCANNING SAST SECRET_DETECTION])
  end
end

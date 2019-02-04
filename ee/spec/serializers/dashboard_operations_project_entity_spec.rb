# frozen_string_literal: true

require 'spec_helper'

describe DashboardOperationsProjectEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:resource) { Dashboard::Operations::ListService::DashboardProject.new(project, nil, 0, nil) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has all required fields' do
    expect(subject).to include(:remove_path, :alert_count)
    expect(subject.first).to include(:id)
  end
end

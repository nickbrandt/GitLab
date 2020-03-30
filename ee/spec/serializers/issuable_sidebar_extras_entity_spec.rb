# frozen_string_literal: true

require 'spec_helper'

describe IssuableSidebarExtrasEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:resource) { create(:issue, project: project, assignees: [user]) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'exposes is_gitlab_employee field for assignees' do
    expect(subject[:assignees].first).to include(:is_gitlab_employee)
  end
end

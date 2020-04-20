# frozen_string_literal: true

RSpec.shared_context 'status page enabled' do
  before do
    project.add_maintainer(user)

    stub_licensed_features(status_page: true)

    unless project.status_page_setting
      create(:status_page_setting, :enabled, project: project)
      project.reload
    end
  end
end

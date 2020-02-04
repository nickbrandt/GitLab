# frozen_string_literal: true

RSpec.shared_examples 'a created deploy token' do
  it 'creates deploy token' do
    expect { deploy_token }.to change { DeployToken.active.count }.by(1)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to render_template(:show)
  end
end

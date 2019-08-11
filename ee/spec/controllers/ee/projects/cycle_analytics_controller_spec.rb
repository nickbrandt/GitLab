# frozen_string_literal: true

require 'spec_helper'

describe Projects::CycleAnalyticsController do
  it_behaves_like 'cycle analytics duration chart endpoint' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end
  end
end

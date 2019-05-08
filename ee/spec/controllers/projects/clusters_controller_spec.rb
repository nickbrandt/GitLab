# frozen_string_literal: true

require 'spec_helper'

describe Projects::ClustersController do
  set(:project) { create(:project) }

  it_behaves_like 'cluster metrics' do
    let(:clusterable) { project }

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp, projects: [project])
    end

    let(:metrics_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: cluster
      }
    end
  end
end

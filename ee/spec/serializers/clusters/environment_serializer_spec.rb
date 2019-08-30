# frozen_string_literal: true

require 'spec_helper'

describe Clusters::EnvironmentSerializer do
  include KubernetesHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project, namespace: user.namespace) }
  set(:cluster) { create(:cluster) }

  let(:resource) { create(:environment, project: project) }

  let(:json_entity) do
    described_class.new(cluster: cluster, current_user: user)
      .represent(resource)
      .with_indifferent_access
  end

  it 'matches clusters/environment json schema' do
    expect(json_entity).to match_schema('clusters/environment', dir: 'ee')
  end
end

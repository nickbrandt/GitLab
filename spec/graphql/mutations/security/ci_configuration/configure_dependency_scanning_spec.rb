# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::ConfigureDependencyScanning do
  include GraphqlHelpers

  let(:service) { ::Security::CiConfiguration::DependencyScanningCreateService }

  subject { resolve(described_class, args: { project_path: project.full_path, configuration: {} }, ctx: { current_user: user }) }

  include_examples 'graphql mutations security ci configuration'
end

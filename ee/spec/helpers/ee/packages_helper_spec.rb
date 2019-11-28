# frozen_string_literal: true

require 'spec_helper'

describe EE::PackagesHelper do
  let(:base_url) { "#{Gitlab.config.gitlab.url}/api/v4/" }

  describe 'package_registry_project_url' do
    it 'returns maven registry url when registry_type is not provided' do
      url = helper.package_registry_project_url(1)

      expect(url).to eq("#{base_url}projects/1/packages/maven")
    end

    it 'returns specified registry url when registry_type is provided' do
      url = helper.package_registry_project_url(1, :npm)

      expect(url).to eq("#{base_url}projects/1/packages/npm")
    end
  end
end

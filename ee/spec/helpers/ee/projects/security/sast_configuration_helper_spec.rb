# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::SastConfigurationHelper do
  let_it_be(:project) { create(:project) }
  let(:project_path) { project.full_path }
  let(:docs_path) { help_page_path('user/application_security/sast/index', anchor: 'configuration') }

  describe '#sast_configuration_data' do
    subject { helper.sast_configuration_data(project) }

    it {
      is_expected.to eq({
        sast_documentation_path: docs_path,
        project_path: project_path
      })
    }
  end
end

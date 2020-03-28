# frozen_string_literal: true

require 'spec_helper'

describe Service do
  describe 'Available services' do
    let(:ee_services) do
      %w(
        github
        jenkins
        jenkins_deprecated
      )
    end

    it { expect(described_class.available_services_names).to include(*ee_services) }
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe BasePolicy do
  include ExternalAuthorizationServiceHelpers

  describe 'read cross project' do
    context 'when an external authorization service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it 'allows auditors' do
        expect(described_class.new(build(:auditor), nil)).to be_allowed(:read_cross_project)
      end
    end
  end
end

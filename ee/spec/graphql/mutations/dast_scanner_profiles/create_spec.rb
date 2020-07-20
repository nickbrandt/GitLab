# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastScannerProfiles::Create do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:profile_name) { SecureRandom.hex }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        profile_name: profile_name
      )
    end

    context 'when the project does not exist' do
      let(:full_path) { SecureRandom.hex }

      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user is not associated with the project' do
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can run a dast scan' do
      before do
        group.add_owner(user)
      end

      it 'stubs out the response' do
        expect(subject[:errors]).to eq(['Not implemented'])
      end

      context 'when security_on_demand_scans_feature_flag is disabled' do
        before do
          stub_feature_flags(security_on_demand_scans_feature_flag: false)
        end

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end
end

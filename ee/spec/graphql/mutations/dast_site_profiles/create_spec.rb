# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastSiteProfiles::Create do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:full_path) { project.full_path }
  let(:profile_name) { SecureRandom.hex }
  let(:target_url) { FFaker::Internet.uri(:https) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        profile_name: profile_name,
        target_url: target_url
      )
    end

    context 'when on demand scan feature is not enabled' do
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when on demand scan feature is enabled' do
      before do
        stub_feature_flags(security_on_demand_scans_feature_flag: true)
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

      context 'when the user is an owner' do
        it 'stubs out the response' do
          group.add_owner(user)

          expect(subject[:errors]).to eq(['Not implemented'])
        end
      end

      context 'when the user is a maintainer' do
        it 'stubs out the response' do
          project.add_maintainer(user)

          expect(subject[:errors]).to eq(['Not implemented'])
        end
      end

      context 'when the user is a developer' do
        it 'stubs out the response' do
          project.add_developer(user)

          expect(subject[:errors]).to eq(['Not implemented'])
        end
      end
    end
  end
end

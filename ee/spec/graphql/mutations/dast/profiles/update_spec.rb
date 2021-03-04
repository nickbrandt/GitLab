# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Dast::Profiles::Update do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_profile, reload: true) { create(:dast_profile, project: project, branch_name: 'audio') }

  let(:dast_profile_gid) { dast_profile.to_global_id }

  let(:params) do
    {
      id: dast_profile_gid,
      name: SecureRandom.hex,
      description: SecureRandom.hex,
      branch_name: 'orphaned-branch',
      dast_site_profile_id: global_id_of(create(:dast_site_profile, project: project)),
      dast_scanner_profile_id: global_id_of(create(:dast_scanner_profile, project: project))
    }
  end

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject { mutation.resolve(**params.merge(full_path: project.full_path)) }

    shared_examples 'an unrecoverable failure' do |parameter|
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the feature is licensed' do
      context 'when the project does not exist' do
        before do
          allow_next_instance_of(ProjectsFinder) do |finder|
            allow(finder).to receive(:execute).and_return(nil)
          end
        end

        it_behaves_like 'an unrecoverable failure'
      end

      context 'when the user cannot read the project' do
        it_behaves_like 'an unrecoverable failure'
      end

      context 'when the user can update a DAST profile' do
        before do
          project.add_developer(user)
        end

        it 'returns the profile' do
          expect(subject[:dast_profile]).to be_a(Dast::Profile)
        end

        it 'updates the profile' do
          subject

          updated_dast_profile = dast_profile.reload

          aggregate_failures do
            expect(global_id_of(updated_dast_profile.dast_site_profile)).to eq(params[:dast_site_profile_id])
            expect(global_id_of(updated_dast_profile.dast_scanner_profile)).to eq(params[:dast_scanner_profile_id])
            expect(updated_dast_profile.name).to eq(params[:name])
            expect(updated_dast_profile.description).to eq(params[:description])
            expect(updated_dast_profile.branch_name).to eq(params[:branch_name])
          end
        end

        context 'when the feature flag dast_branch_selection is disabled' do
          it 'does not set the branch_name' do
            stub_feature_flags(dast_branch_selection: false)

            expect(subject[:dast_profile].branch_name).to eq(dast_profile.branch_name)
          end
        end

        context 'when the dast_profile does not exist' do
          let(:dast_profile_gid) { Gitlab::GlobalId.build(nil, model_name: 'Dast::Profile', id: 'does_not_exist') }

          it_behaves_like 'an unrecoverable failure'
        end

        context 'when updating fails' do
          it 'returns an error' do
            allow_next_instance_of(::Dast::Profiles::UpdateService) do |service|
              allow(service).to receive(:execute).and_return(
                ServiceResponse.error(message: 'Profile failed to update')
              )
            end

            expect(subject[:errors]).to include('Profile failed to update')
          end
        end

        context 'when the feature is not enabled' do
          before do
            stub_feature_flags(dast_saved_scans: false)
          end

          it_behaves_like 'an unrecoverable failure'
        end
      end
    end
  end
end
